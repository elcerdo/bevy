use super::image::PartialSumImages;
use super::pipeline::PartialSumPipeline;
use super::PartialSumSettings;

use bevy::prelude::*;
use bevy::render::extract_component::ComponentUniforms;
use bevy::render::render_asset::RenderAssets;
use bevy::render::render_resource::{BindGroup, BindGroupEntries};
use bevy::render::renderer::RenderDevice;
use bevy::render::texture::GpuImage;

//////////////////////////////////////////////////////////////////////

#[derive(Resource)]
pub struct PartialSumBindGroups {
    pub group_a_to_b: BindGroup,
    pub group_b_to_a: BindGroup,
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

    let view_data = gpu_images.get(&images.image_data).unwrap();
    let view_a = gpu_images.get(&images.image_a).unwrap();
    let view_b = gpu_images.get(&images.image_b).unwrap();

    let group_a_to_b = render_device.create_bind_group(
        Some("group_a_to_b"),
        &pipeline.group_layout,
        &BindGroupEntries::sequential((
            &view_data.texture_view,
            &view_a.texture_view,
            &view_b.texture_view,
            settings.clone(),
        )),
    );
    let group_b_to_a = render_device.create_bind_group(
        Some("group_b_to_a"),
        &pipeline.group_layout,
        &BindGroupEntries::sequential((
            &view_data.texture_view,
            &view_b.texture_view,
            &view_a.texture_view,
            settings.clone(),
        )),
    );

    // insert bind groups
    commands.insert_resource(PartialSumBindGroups {
        group_a_to_b,
        group_b_to_a,
    });
}
