use super::image::PartialSumImages;
use super::pipeline::PartialSumPipeline;
use super::PartialSumSettings;

use bevy::prelude::*;
use bevy::render::extract_component::ComponentUniforms;
use bevy::render::render_asset::RenderAssets;
use bevy::render::render_resource::{BindGroup, BindGroupEntries};
use bevy::render::renderer::RenderDevice;
use bevy::render::texture::GpuImage;
// use bevy::render::Extract;

//////////////////////////////////////////////////////////////////////

#[derive(Resource)]
pub struct PartialSumBindGroups {
    pub group_main: BindGroup,
}

pub fn increment_count(
    // settings: Extract<Query<&PartialSumSettings>>,
    mut settings: Query<&mut PartialSumSettings>,
) {
    if settings.is_empty() {
        return;
    }
    let mut settings = settings.single_mut().unwrap();
    warn!("increment_count {:?}", settings);
    settings.count += 1; // this has no effect
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
            settings.clone(),
        )),
    );

    // insert bind groups
    commands.insert_resource(PartialSumBindGroups { group_main });
}
