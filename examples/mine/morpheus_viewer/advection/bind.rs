use crate::advection::image::AdvectionImages;
use crate::advection::image::AdvectionSettings;
use crate::advection::pipeline::AdvectionPipeline;

use bevy::prelude::*;
use bevy::render::extract_component::ComponentUniforms;
use bevy::render::render_asset::RenderAssets;
use bevy::render::render_resource::{BindGroup, BindGroupEntries};
use bevy::render::renderer::RenderDevice;
use bevy::render::texture::GpuImage;

//////////////////////////////////////////////////////////////////////

#[derive(Resource)]
pub struct AdvectionBindGroups {
    pub group_a_to_b: BindGroup,
    pub group_b_to_a: BindGroup,
}

pub fn prepare_bind_groups(
    mut commands: Commands,
    settings: Res<ComponentUniforms<AdvectionSettings>>,
    pipeline: Res<AdvectionPipeline>,
    images: Res<AdvectionImages>,
    gpu_images: Res<RenderAssets<GpuImage>>,
    render_device: Res<RenderDevice>,
) {
    let settings = settings.uniforms().binding().unwrap();

    let view_a = gpu_images.get(&images.image_a).unwrap();
    let view_b = gpu_images.get(&images.image_b).unwrap();
    // let view_voronoi = gpu_images.get(&images.image_voronoi).unwrap();
    let view_pattern = gpu_images.get(&images.image_pattern).unwrap();

    if gpu_images.get(&images.image_voronoi).is_none() {
        warn!("ksldjfkjsd");
    }

    let group_a_to_b = render_device.create_bind_group(
        Some("group_a_to_b"),
        &pipeline.group_layout,
        &BindGroupEntries::sequential((
            &view_a.texture_view,
            &view_b.texture_view,
            // &view_voronoi.texture_view,
            &view_pattern.texture_view,
            settings.clone(),
        )),
    );
    let group_b_to_a = render_device.create_bind_group(
        Some("group_b_to_a"),
        &pipeline.group_layout,
        &BindGroupEntries::sequential((
            &view_b.texture_view,
            &view_a.texture_view,
            // &view_voronoi.texture_view,
            &view_pattern.texture_view,
            settings.clone(),
        )),
    );

    // insert bind groups
    commands.insert_resource(AdvectionBindGroups {
        group_a_to_b,
        group_b_to_a,
    });
}
