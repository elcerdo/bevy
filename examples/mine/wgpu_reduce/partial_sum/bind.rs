use super::image::PartialSumImages;
use super::pipeline::PartialSumPipeline;
use super::pipeline::PILELINE_COUNT_INVALID;
use super::PartialSumSettings;

use bevy::prelude::*;
use bevy::render::extract_component::ComponentUniforms;
use bevy::render::render_asset::RenderAssets;
use bevy::render::render_resource::{BindGroup, BindGroupEntries};
use bevy::render::renderer::RenderDevice;
use bevy::render::texture::GpuImage;
use bevy::render::Extract;

//////////////////////////////////////////////////////////////////////

#[derive(Resource)]
pub struct PartialSumBindGroups {
    pub group_main: BindGroup,
}

pub fn sync_settings(
    settings: Extract<Query<&PartialSumSettings>>,
    pipeline: Res<PartialSumPipeline>,
) {
    if settings.is_empty() {
        return;
    }
    let settings = settings.single().unwrap();
    // settings.count = pipeline.count;
    if pipeline.count != PILELINE_COUNT_INVALID {
        warn!("sync_settings {} {:?}", pipeline.count, settings);
    }
}

pub fn prepare_bind_groups(
    mut commands: Commands,
    settings: Res<ComponentUniforms<PartialSumSettings>>,
    pipeline: Res<PartialSumPipeline>,
    images: Res<PartialSumImages>,
    gpu_images: Res<RenderAssets<GpuImage>>,
    render_device: Res<RenderDevice>,
) {
    let settings = settings.uniforms().binding().unwrap();

    let view_initial = gpu_images.get(&images.image_initial).unwrap();
    let view_current = gpu_images.get(&images.image_current).unwrap();

    let group_main = render_device.create_bind_group(
        Some("group_main"),
        &pipeline.group_layout,
        &BindGroupEntries::sequential((
            &view_initial.texture_view,
            &view_current.texture_view,
            settings.clone(), // FIXME update count
        )),
    );

    // insert bind groups
    commands.insert_resource(PartialSumBindGroups { group_main });
}
