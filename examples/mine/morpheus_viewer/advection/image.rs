use bevy::math::Vec3;
use bevy::prelude::*;
use bevy::render::extract_component::ExtractComponent;
use bevy::render::extract_resource::ExtractResource;
use bevy::render::render_asset::RenderAssetUsages;
use bevy::render::render_resource::ShaderType;

use crate::advection::consts::TEXTURE_FORMAT;
use crate::advection::consts::TEXTURE_SIZE;

//////////////////////////////////////////////////////////////////////

#[derive(Component, ShaderType, ExtractComponent, Clone)]
pub struct AdvectionSettings {
    rng_seed: u32,
    bbox_center: Vec3,
}

impl Default for AdvectionSettings {
    fn default() -> Self {
        Self {
            rng_seed: 42,
            bbox_center: Vec3::ZERO,
        }
    }
}

#[derive(Resource, Clone, ExtractResource)]
pub struct AdvectionImages {
    pub image_a: Handle<Image>,
    pub image_b: Handle<Image>,
}

pub fn populate_plane_and_images(
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
        AdvectionSettings::default(),
    ));

    // insert images
    commands.insert_resource(AdvectionImages { image_a, image_b });
}
