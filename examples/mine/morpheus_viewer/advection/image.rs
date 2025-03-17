use crate::advection::warped_material::WarpedMaterial;

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
    texture_size: UVec2,
    pub learning_rate: f32,
}

impl Default for AdvectionSettings {
    fn default() -> Self {
        Self {
            texture_size: UVec2::new(TEXTURE_SIZE.0, TEXTURE_SIZE.1),
            learning_rate: 45e-2,
        }
    }
}

#[derive(Resource, Clone, ExtractResource)]
pub struct AdvectionImages {
    pub image_a: Handle<Image>,
    pub image_b: Handle<Image>,
    pub image_pattern: Handle<Image>,
}

pub fn populate_planes_and_images(
    mut commands: Commands,
    mut images: ResMut<Assets<Image>>,
    mut meshes: ResMut<Assets<Mesh>>,
    mut standard_materials: ResMut<Assets<StandardMaterial>>,
    mut warped_materials: ResMut<Assets<WarpedMaterial>>,
    asset_server: Res<AssetServer>,
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
    let image_b = images.add(image.clone());
    let image_pattern = images.add(image);

    // magic planes
    commands.spawn((
        Mesh3d(meshes.add(Plane3d::new(Vec3::Y, Vec2::ONE))),
        MeshMaterial3d(standard_materials.add(StandardMaterial {
            perceptual_roughness: 1.0,
            metallic: 0.0,
            base_color_texture: Some(image_a.clone()),
            ..default()
        })),
        Transform::from_xyz(-3.0, 0.0, -1.0),
        AdvectionSettings::default(),
    ));
    commands.spawn((
        Mesh3d(meshes.add(Plane3d::new(Vec3::Y, Vec2::ONE))),
        MeshMaterial3d(standard_materials.add(StandardMaterial {
            perceptual_roughness: 1.0,
            metallic: 0.0,
            base_color_texture: Some(image_b.clone()),
            ..default()
        })),
        Transform::from_xyz(-1.0, 0.0, -1.0),
        AdvectionSettings::default(),
    ));
    commands.spawn((
        Mesh3d(meshes.add(Plane3d::new(Vec3::Y, Vec2::ONE))),
        MeshMaterial3d(standard_materials.add(StandardMaterial {
            perceptual_roughness: 1.0,
            metallic: 0.0,
            base_color_texture: Some(image_pattern.clone()),
            ..default()
        })),
        Transform::from_xyz(1.0, 0.0, -1.0),
        AdvectionSettings::default(),
    ));

    let image_voronoi = asset_server.load::<Image>("textures/voronoi.png");
    commands.spawn((
        Mesh3d(meshes.add(Plane3d::new(Vec3::Y, Vec2::ONE))),
        MeshMaterial3d(warped_materials.add(WarpedMaterial::new(
            image_voronoi.clone(),
            image_pattern.clone(),
        ))),
        Transform::from_xyz(3.0, 0.0, -1.0),
    ));
    // commands.spawn((
    //     Mesh3d(meshes.add(Plane3d::new(Vec3::Y, Vec2::ONE))),
    //     MeshMaterial3d(standard_materials.add(StandardMaterial {
    //         perceptual_roughness: 1.0,
    //         metallic: 0.0,
    //         base_color_texture: Some(image_voronoi.clone()),
    //         ..default()
    //     })),
    //     Transform::from_xyz(3.0, 0.0, -3.0),
    // ));

    // insert images
    commands.insert_resource(AdvectionImages {
        image_a,
        image_b,
        image_pattern,
    });
}
