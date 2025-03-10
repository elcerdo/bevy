use bevy::render::extract_component::{
    ComponentUniforms, ExtractComponent, ExtractComponentPlugin, UniformComponentPlugin,
};
use bevy::render::extract_resource::{ExtractResource, ExtractResourcePlugin};
use bevy::render::render_asset::{RenderAssetUsages, RenderAssets};
use bevy::render::render_graph::{Node, RenderGraph, RenderLabel};
use bevy::render::render_resource::{
    binding_types::{texture_storage_2d, uniform_buffer},
    BindGroup, BindGroupEntries, BindGroupLayout, CachedComputePipelineId, ShaderType,
    TextureFormat,
};
use bevy::render::renderer::RenderDevice;
use bevy::render::texture::GpuImage;
use bevy::render::{Render, RenderApp, RenderSet};

use bevy::prelude::*;

use std::borrow::Cow;

const SHADER_ASSET_PATH: &str = "shaders/offroad/simu_compute.wgsl";
const TEXTURE_FORMAT: TextureFormat = TextureFormat::Rgba32Float;
const SIMU_SIZE: (u32, u32) = (1024, 1024);
const WORKGROUP_SIZE: u32 = 8;

//////////////////////////////////////////////////////////////////////

#[derive(Component, ShaderType, ExtractComponent, Clone)]
struct SimuSettings {
    rng_seed: u32,
}
pub struct SimuPlugin;

#[derive(Hash, Clone, Eq, PartialEq, Debug, RenderLabel)]
struct SimuNodeMarker;

impl Plugin for SimuPlugin {
    fn build(&self, app: &mut App) {
        info!("** build_simu **");

        app.add_plugins((
            // The settings will be a component that lives in the main world but will
            // be extracted to the render world every frame.
            // This makes it possible to control the effect from the main world.
            // This plugin will take care of extracting it automatically.
            // It's important to derive [`ExtractComponent`] on [`PostProcessingSettings`]
            // for this plugin to work correctly.
            ExtractComponentPlugin::<SimuSettings>::default(),
            // The settings will also be the data used in the shader.
            // This plugin will prepare the component for the GPU by creating a uniform buffer
            // and writing the data to that buffer every frame.
            UniformComponentPlugin::<SimuSettings>::default(),
        ));

        // Extract the game of life image resource from the main world into the render world
        // for operation on by the compute shader and display on the sprite.
        app.add_plugins(ExtractResourcePlugin::<SimuImages>::default());

        app.add_systems(Startup, populate_simu_plane_and_images);

        let render_app = app.sub_app_mut(RenderApp);

        let mut render_graph = render_app.world_mut().resource_mut::<RenderGraph>();
        render_graph.add_node(SimuNodeMarker, SimuNode::default());
        render_graph.add_node_edge(SimuNodeMarker, bevy::render::graph::CameraDriverLabel);

        render_app.add_systems(
            Render,
            update_bind_groups.in_set(RenderSet::PrepareBindGroups),
        );
    }
    fn finish(&self, app: &mut App) {
        info!("** simu_finish **");
        let render_app = app.sub_app_mut(RenderApp);
        render_app.init_resource::<SimuPipeline>();
    }
}

//////////////////////////////////////////////////////////////////////

#[derive(Resource, Clone, ExtractResource)]
struct SimuImages {
    image_a: Handle<Image>,
    image_b: Handle<Image>,
}

fn populate_simu_plane_and_images(
    mut commands: Commands,
    mut images: ResMut<Assets<Image>>,
    mut meshes: ResMut<Assets<Mesh>>,
    mut materials: ResMut<Assets<StandardMaterial>>,
) {
    use bevy::render::render_resource::*;

    info!("** populate_simu_plane_and_images **");

    let mut image = Image::new_fill(
        Extent3d {
            width: SIMU_SIZE.0,
            height: SIMU_SIZE.1,
            depth_or_array_layers: 1,
        },
        TextureDimension::D2,
        &[0, 0, 0, 255],
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
        Mesh3d(
            meshes.add(
                Plane3d::default()
                    .mesh()
                    .size(400.0, 400.0)
                    .subdivisions(20),
            ),
        ),
        MeshMaterial3d(materials.add(StandardMaterial {
            perceptual_roughness: 1.0,
            metallic: 0.0,
            base_color_texture: Some(image_a.clone()),
            ..StandardMaterial::default()
        })),
        Transform::from_xyz(100.0, -0.25, -100.0),
        SimuSettings { rng_seed: 42 },
    ));

    // insert images
    commands.insert_resource(SimuImages { image_a, image_b });
}

//////////////////////////////////////////////////////////////////////

#[derive(Resource)]
struct SimuPipeline {
    group_layout: BindGroupLayout,
    init_pipeline: CachedComputePipelineId,
    update_pipeline: CachedComputePipelineId,
}

impl FromWorld for SimuPipeline {
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
                    uniform_buffer::<SimuSettings>(true),
                ),
            ),
        );

        let shader: Handle<Shader> = world.load_asset(SHADER_ASSET_PATH);

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

        SimuPipeline {
            group_layout,
            init_pipeline,
            update_pipeline,
        }
    }
}

//////////////////////////////////////////////////////////////////////

#[derive(Resource)]
struct SimuBindGroups {
    group_direct: BindGroup,
    group_indirect: BindGroup,
}

fn update_bind_groups(
    mut commands: Commands,
    simu_settings: Res<ComponentUniforms<SimuSettings>>,
    simu_pipeline: Res<SimuPipeline>,
    simu_images: Res<SimuImages>,
    gpu_images: Res<RenderAssets<GpuImage>>,
    render_device: Res<RenderDevice>,
) {
    let simu_binding = simu_settings.uniforms().binding();
    assert!(simu_binding.is_some());

    let view_a = gpu_images.get(&simu_images.image_a).unwrap();
    let view_b = gpu_images.get(&simu_images.image_b).unwrap();
    let group_direct = render_device.create_bind_group(
        Some("group_direct"),
        &simu_pipeline.group_layout,
        &BindGroupEntries::sequential((
            &view_a.texture_view,
            &view_b.texture_view,
            simu_binding.clone().unwrap(),
        )),
    );
    let group_indirect = render_device.create_bind_group(
        Some("group_indirect"),
        &simu_pipeline.group_layout,
        &BindGroupEntries::sequential((
            &view_b.texture_view,
            &view_a.texture_view,
            simu_binding.unwrap(),
        )),
    );

    // insert bind groups
    commands.insert_resource(SimuBindGroups {
        group_direct,
        group_indirect,
    });
}

//////////////////////////////////////////////////////////////////////

#[derive(Default)]
enum SimuState {
    #[default]
    Loading,
    Init,
    Update(bool),
}

#[derive(Default)]
struct SimuNode {
    state: SimuState,
}

impl Node for SimuNode {
    fn update(&mut self, world: &mut World) {
        use bevy::render::render_resource::*;

        let pipeline = world.resource::<SimuPipeline>();
        let pipeline_cache = world.resource::<PipelineCache>();

        // if the corresponding pipeline has loaded, transition to the next stage
        match self.state {
            SimuState::Loading => {
                let init_ok = matches!(
                    pipeline_cache.get_compute_pipeline_state(pipeline.init_pipeline),
                    CachedPipelineState::Ok(_)
                );
                let update_ok = matches!(
                    pipeline_cache.get_compute_pipeline_state(pipeline.init_pipeline),
                    CachedPipelineState::Ok(_)
                );
                if init_ok && update_ok {
                    self.state = SimuState::Init;
                }
            }
            SimuState::Init => {
                self.state = SimuState::Update(true);
            }
            SimuState::Update(flipped) => {
                self.state = SimuState::Update(!flipped);
            }
        }
    }

    fn run(
        &self,
        _graph_context: &mut bevy::render::render_graph::RenderGraphContext,
        render_context: &mut bevy::render::renderer::RenderContext,
        world: &World,
    ) -> Result<(), bevy::render::render_graph::NodeRunError> {
        use bevy::render::render_resource::*;

        let bind_groups = world.resource::<SimuBindGroups>();
        let pipeline_cache = world.resource::<PipelineCache>();
        let pipeline_simu = world.resource::<SimuPipeline>();

        let mut pass = render_context
            .command_encoder()
            .begin_compute_pass(&ComputePassDescriptor::default());

        // select the pipeline based on the current state
        let should_dispatch = match self.state {
            SimuState::Loading => false,
            SimuState::Init => {
                let init_pipeline = pipeline_cache
                    .get_compute_pipeline(pipeline_simu.init_pipeline)
                    .unwrap();
                pass.set_bind_group(0, &bind_groups.group_direct, &[0]);
                pass.set_pipeline(init_pipeline);
                true
            }
            SimuState::Update(flipped) => {
                let update_pipeline = pipeline_cache
                    .get_compute_pipeline(pipeline_simu.update_pipeline)
                    .unwrap();
                pass.set_bind_group(
                    0,
                    if !flipped {
                        &bind_groups.group_direct
                    } else {
                        &bind_groups.group_indirect
                    },
                    &[0],
                );
                pass.set_pipeline(update_pipeline);
                true
            }
        };

        if should_dispatch {
            pass.dispatch_workgroups(
                SIMU_SIZE.0 / WORKGROUP_SIZE,
                SIMU_SIZE.1 / WORKGROUP_SIZE,
                1,
            );
        }

        Ok(())
    }
}
