use super::PartialSumSettings;

use super::consts::TEXTURE_FORMAT;

use bevy::prelude::*;
use bevy::render::render_resource::{
    binding_types::{texture_storage_2d, uniform_buffer},
    BindGroupLayout, CachedComputePipelineId,
};
use bevy::render::renderer::RenderDevice;

use std::borrow::Cow;

pub const SHADER_PATH: &str = "shaders/wgpu_reduce/partial_sum.wgsl";

//////////////////////////////////////////////////////////////////////

#[derive(Resource)]
pub struct PartialSumPipeline {
    pub group_layout: BindGroupLayout,
    pub init_id: CachedComputePipelineId,
    pub update_id: CachedComputePipelineId,
    pub count: u32,
}

pub const PILELINE_COUNT_INVALID: u32 = 256;

impl FromWorld for PartialSumPipeline {
    fn from_world(world: &mut World) -> Self {
        use bevy::render::render_resource::*;

        let render_device = world.resource::<RenderDevice>();
        let pipeline_cache = world.resource::<PipelineCache>();

        let group_layout = render_device.create_bind_group_layout(
            None,
            &BindGroupLayoutEntries::sequential(
                ShaderStages::COMPUTE,
                (
                    texture_storage_2d(TEXTURE_FORMAT, StorageTextureAccess::WriteOnly),
                    texture_storage_2d(TEXTURE_FORMAT, StorageTextureAccess::ReadWrite),
                    uniform_buffer::<PartialSumSettings>(false),
                ),
            ),
        );

        let shader: Handle<Shader> = world.load_asset(SHADER_PATH);

        let init_id = pipeline_cache.queue_compute_pipeline(ComputePipelineDescriptor {
            label: Some(Cow::from("init_pipeline_id")),
            layout: vec![group_layout.clone()],
            push_constant_ranges: Vec::new(),
            shader: shader.clone(),
            shader_defs: vec![],
            entry_point: Cow::from("init"),
            zero_initialize_workgroup_memory: false,
        });

        let update_id = pipeline_cache.queue_compute_pipeline(ComputePipelineDescriptor {
            label: Some(Cow::from("update_pipeline_id")),
            layout: vec![group_layout.clone()],
            push_constant_ranges: Vec::new(),
            shader,
            shader_defs: vec![],
            entry_point: Cow::from("update"),
            zero_initialize_workgroup_memory: false,
        });

        PartialSumPipeline {
            group_layout,
            init_id,
            update_id,
            count: PILELINE_COUNT_INVALID,
        }
    }
}
