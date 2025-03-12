use crate::advection::image::AdvectionSettings;

use bevy::prelude::*;
use bevy::render::extract_resource::ExtractResource;

use bevy::render::render_resource::{
    binding_types::{texture_storage_2d /*, uniform_buffer */},
    BindGroupLayout, CachedComputePipelineId, /* ShaderType */
};
use bevy::render::renderer::RenderDevice;

use std::borrow::Cow;

use crate::advection::consts::SHADER_PATH;
use crate::advection::consts::TEXTURE_FORMAT;

//////////////////////////////////////////////////////////////////////

#[derive(Resource, Clone, Default, ExtractResource)]
pub struct AdvectionTriggers {
    pub should_reinit: bool,
}

#[derive(Resource)]
pub struct AdvectionPipeline {
    pub triggers: AdvectionTriggers,
    pub group_layout: BindGroupLayout,
    pub init_pipeline: CachedComputePipelineId,
    pub update_pipeline: CachedComputePipelineId,
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
                    // uniform_buffer::<AdvectionSettings>(true),
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
            triggers: AdvectionTriggers::default(),
            group_layout,
            init_pipeline,
            update_pipeline,
        }
    }
}

// should be used in main app

pub fn update_triggers_keyboard(
    mut triggers: ResMut<AdvectionTriggers>,
    keyboard: Res<ButtonInput<KeyCode>>,
) {
    let should_reinit = keyboard.pressed(KeyCode::Space);
    triggers.should_reinit = should_reinit;
}

// should be used in render app after extraction

pub fn copy_triggers(triggers: Res<AdvectionTriggers>, mut pipeline: ResMut<AdvectionPipeline>) {
    pipeline.triggers = triggers.clone();
}
