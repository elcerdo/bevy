use bevy::prelude::*;
use bevy::render::extract_resource::{ExtractResource, ExtractResourcePlugin};
use bevy::render::graph::CameraDriverLabel;
use bevy::render::render_asset::{RenderAssetUsages, RenderAssets};
use bevy::render::render_graph::{Node, RenderGraph, RenderLabel};
use bevy::render::render_resource::{
    binding_types::{texture_storage_2d /*, uniform_buffer */},
    BindGroup, BindGroupEntries, BindGroupLayout, CachedComputePipelineId, /* ShaderType */
    TextureFormat,
};
use bevy::render::renderer::RenderDevice;
use bevy::render::texture::GpuImage;
use bevy::render::{Render, RenderApp, RenderSet};

use std::borrow::Cow;

const SHADER_PATH: &str = "shaders/morpheus/advection.wgsl";
const TEXTURE_FORMAT: TextureFormat = TextureFormat::Rgba32Float;
const TEXTURE_SIZE: (u32, u32) = (256, 256);
const WORKGROUP_SIZE: u32 = 8;

//////////////////////////////////////////////////////////////////////

pub struct AdvectionPlugin;

#[derive(Hash, Clone, Eq, PartialEq, Debug, RenderLabel)]
enum AdvectionNodes {
    Main,
}

impl Plugin for AdvectionPlugin {
    fn build(&self, app: &mut App) {
        // app.add_plugins((
        //     // The settings will be a component that lives in the main world but will
        //     // be extracted to the render world every frame.
        //     // This makes it possible to control the effect from the main world.
        //     // This plugin will take care of extracting it automatically.
        //     // It's important to derive [`ExtractComponent`] on [`PostProcessingSettings`]
        //     // for this plugin to work correctly.
        //     ExtractComponentPlugin::<SimuSettings>::default(),
        //     // The settings will also be the data used in the shader.
        //     // This plugin will prepare the component for the GPU by creating a uniform buffer
        //     // and writing the data to that buffer every frame.
        //     UniformComponentPlugin::<SimuSettings>::default(),
        // ));

        // Extract the game of life image resource from the main world into the render world
        // for operation on by the compute shader and display on the sprite.
        app.add_plugins(ExtractResourcePlugin::<AdvectionImages>::default());
        // app.add_plugins(ExtractResourcePlugin::<SimuTriggers>::default());
        app.add_systems(Startup, populate_plane_and_images);
        // app.add_systems(Update, update_simu_triggers);

        let render_app = app.sub_app_mut(RenderApp);
        render_app.add_systems(
            Render,
            update_bind_groups.in_set(RenderSet::PrepareBindGroups),
        );
        let mut render_graph = render_app.world_mut().resource_mut::<RenderGraph>();
        render_graph.add_node(AdvectionNodes::Main, MainNode::default());
        render_graph.add_node_edge(AdvectionNodes::Main, CameraDriverLabel);
    }
    fn finish(&self, app: &mut App) {
        // app.init_resource::<SimuTriggers>();

        let render_app = app.sub_app_mut(RenderApp);
        render_app.init_resource::<AdvectionPipeline>();
    }
}

//////////////////////////////////////////////////////////////////////

#[derive(Resource, Clone, ExtractResource)]
struct AdvectionImages {
    image_a: Handle<Image>,
    image_b: Handle<Image>,
}

fn populate_plane_and_images(
    mut commands: Commands,
    mut images: ResMut<Assets<Image>>,
    mut meshes: ResMut<Assets<Mesh>>,
    mut materials: ResMut<Assets<StandardMaterial>>,
) {
    use bevy::render::render_resource::*;

    info!("** populate_plane_and_images **");

    let mut image = Image::new_fill(
        Extent3d {
            width: TEXTURE_SIZE.0,
            height: TEXTURE_SIZE.1,
            depth_or_array_layers: 1,
        },
        TextureDimension::D2,
        &[255, 0, 255, 255],
        TEXTURE_FORMAT,
        RenderAssetUsages::RENDER_WORLD,
    );
    image.texture_descriptor.usage =
        TextureUsages::COPY_DST | TextureUsages::STORAGE_BINDING | TextureUsages::TEXTURE_BINDING;
    image.sampler = bevy::image::ImageSampler::nearest();

    let image_a = images.add(image.clone());
    let image_b = images.add(image);

    // magic plane
    commands.spawn((
        Mesh3d(meshes.add(Plane3d::new(Vec3::Y, Vec2::ONE))),
        MeshMaterial3d(materials.add(StandardMaterial {
            perceptual_roughness: 1.0,
            metallic: 0.0,
            base_color_texture: Some(image_a.clone()),
            ..default()
        })),
        Transform::from_xyz(-2.6, -1.2, -2.6),
        // SimuSettings::default(),
    ));

    // insert images
    commands.insert_resource(AdvectionImages { image_a, image_b });
}

//////////////////////////////////////////////////////////////////////

// #[derive(Resource, Clone, Default, ExtractResource)]
// struct SimuTriggers {
//     should_reinit: bool,
// }

#[derive(Resource)]
struct AdvectionPipeline {
    // simu_triggers: SimuTriggers,
    group_layout: BindGroupLayout,
    init_pipeline: CachedComputePipelineId,
    update_pipeline: CachedComputePipelineId,
}

impl FromWorld for AdvectionPipeline {
    fn from_world(world: &mut World) -> Self {
        use bevy::render::render_resource::*;

        let render_device = world.resource::<RenderDevice>();
        let pipeline_cache = world.resource::<PipelineCache>();

        let group_layout = render_device.create_bind_group_layout(
            None,
            &BindGroupLayoutEntries::sequential(
                ShaderStages::COMPUTE,
                (
                    texture_storage_2d(TEXTURE_FORMAT, StorageTextureAccess::ReadOnly),
                    texture_storage_2d(TEXTURE_FORMAT, StorageTextureAccess::WriteOnly),
                    // uniform_buffer::<SimuSettings>(true),
                ),
            ),
        );

        let shader: Handle<Shader> = world.load_asset(SHADER_PATH);

        let init_pipeline = pipeline_cache.queue_compute_pipeline(ComputePipelineDescriptor {
            label: Some(Cow::from("init_pipeline")),
            layout: vec![group_layout.clone()],
            push_constant_ranges: Vec::new(),
            shader: shader.clone(),
            shader_defs: vec![],
            entry_point: Cow::from("init"),
            zero_initialize_workgroup_memory: false,
        });

        let update_pipeline = pipeline_cache.queue_compute_pipeline(ComputePipelineDescriptor {
            label: Some(Cow::from("update_pipeline")),
            layout: vec![group_layout.clone()],
            push_constant_ranges: Vec::new(),
            shader,
            shader_defs: vec![],
            entry_point: Cow::from("update"),
            zero_initialize_workgroup_memory: false,
        });

        AdvectionPipeline {
            // simu_triggers: SimuTriggers::default(),
            group_layout,
            init_pipeline,
            update_pipeline,
        }
    }
}

// fn copy_triggers(simu_triggers: Res<SimuTriggers>, mut simu_pipeline: ResMut<SimuPipeline>) {
//     simu_pipeline.simu_triggers = simu_triggers.clone();
// }

//////////////////////////////////////////////////////////////////////

#[derive(Resource)]
struct AdvectionBindGroups {
    group_a_to_b: BindGroup,
    group_b_to_a: BindGroup,
}

fn update_bind_groups(
    mut commands: Commands,
    // simu_settings: Res<ComponentUniforms<SimuSettings>>,
    advection_pipeline: Res<AdvectionPipeline>,
    advection_images: Res<AdvectionImages>,
    gpu_images: Res<RenderAssets<GpuImage>>,
    render_device: Res<RenderDevice>,
) {
    // let simu_binding = simu_settings.uniforms().binding();
    // assert!(simu_binding.is_some());

    let view_a = gpu_images.get(&advection_images.image_a).unwrap();
    let view_b = gpu_images.get(&advection_images.image_b).unwrap();
    let group_a_to_b = render_device.create_bind_group(
        Some("group_a_to_b"),
        &advection_pipeline.group_layout,
        &BindGroupEntries::sequential((
            &view_a.texture_view,
            &view_b.texture_view,
            // simu_binding.clone().unwrap(),
        )),
    );
    let group_b_to_a = render_device.create_bind_group(
        Some("group_b_to_a"),
        &advection_pipeline.group_layout,
        &BindGroupEntries::sequential((
            &view_b.texture_view,
            &view_a.texture_view,
            // simu_binding.unwrap(),
        )),
    );

    // insert bind groups
    commands.insert_resource(AdvectionBindGroups {
        group_a_to_b,
        group_b_to_a,
    });
}

//////////////////////////////////////////////////////////////////////

#[derive(Default)]
enum MainState {
    #[default]
    Loading,
    Init,
    Update(bool),
}

#[derive(Default)]
struct MainNode {
    state: MainState,
}

impl Node for MainNode {
    fn update(&mut self, world: &mut World) {
        use bevy::render::render_resource::*;

        let pipeline = world.resource::<AdvectionPipeline>();
        let pipeline_cache = world.resource::<PipelineCache>();

        // let should_reinit = pipeline.simu_triggers.should_reinit;

        // if the corresponding pipeline has loaded, transition to the next stage
        match self.state {
            MainState::Loading => {
                let init_ok = matches!(
                    pipeline_cache.get_compute_pipeline_state(pipeline.init_pipeline),
                    CachedPipelineState::Ok(_)
                );
                let update_ok = matches!(
                    pipeline_cache.get_compute_pipeline_state(pipeline.init_pipeline),
                    CachedPipelineState::Ok(_)
                );
                if init_ok && update_ok {
                    self.state = MainState::Init;
                }
            }
            MainState::Init => {
                self.state = MainState::Update(true);
            }
            MainState::Update(flipped) => {
                self.state = MainState::Update(!flipped);
            }
        };
    }

    fn run(
        &self,
        _graph_context: &mut bevy::render::render_graph::RenderGraphContext,
        render_context: &mut bevy::render::renderer::RenderContext,
        world: &World,
    ) -> Result<(), bevy::render::render_graph::NodeRunError> {
        use bevy::render::render_resource::*;

        let pipeline = world.resource::<AdvectionPipeline>();
        let bind_groups = world.resource::<AdvectionBindGroups>();
        let pipeline_cache = world.resource::<PipelineCache>();

        let mut pass = render_context
            .command_encoder()
            .begin_compute_pass(&ComputePassDescriptor::default());

        // select the pipeline based on the current state
        let should_dispatch = match self.state {
            MainState::Loading => false,
            MainState::Init => {
                let init_pipeline = pipeline_cache
                    .get_compute_pipeline(pipeline.init_pipeline)
                    .unwrap();
                pass.set_bind_group(0, &bind_groups.group_a_to_b, &[]);
                pass.set_pipeline(init_pipeline);
                true
            }
            MainState::Update(flipped) => {
                let update_pipeline = pipeline_cache
                    .get_compute_pipeline(pipeline.update_pipeline)
                    .unwrap();
                pass.set_bind_group(
                    0,
                    if !flipped {
                        &bind_groups.group_a_to_b
                    } else {
                        &bind_groups.group_b_to_a
                    },
                    &[],
                );
                pass.set_pipeline(update_pipeline);
                true
            }
        };

        if should_dispatch {
            pass.dispatch_workgroups(
                TEXTURE_SIZE.0 / WORKGROUP_SIZE,
                TEXTURE_SIZE.1 / WORKGROUP_SIZE,
                1,
            );
        }

        Ok(())
    }
}
