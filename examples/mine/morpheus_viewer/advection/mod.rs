use bevy::prelude::*;
use bevy::render::extract_resource::{ExtractResource, ExtractResourcePlugin};
use bevy::render::render_asset::{RenderAssetUsages, RenderAssets};
use bevy::render::render_resource::{
    // binding_types::{texture_storage_2d, uniform_buffer},
    // BindGroup, BindGroupEntries, BindGroupLayout, CachedComputePipelineId, ShaderType,
    TextureFormat,
};

// use bevy::color::palettes::css::PURPLE;

const TEXTURE_FORMAT: TextureFormat = TextureFormat::Rgba32Float;
const SIMU_SIZE: (u32, u32) = (1024, 4);

//////////////////////////////////////////////////////////////////////

pub struct AdvectionPlugin;

impl Plugin for AdvectionPlugin {
    fn build(&self, app: &mut App) {
        app.add_systems(Startup, populate_plane_and_images);
    }
}

//////////////////////////////////////////////////////////////////////

// fn populate(
//     mut commands: Commands,
//     mut materials: ResMut<Assets<StandardMaterial>>,
//     mut meshes: ResMut<Assets<Mesh>>,
// ) {
//     commands.spawn((
//         Mesh3d(meshes.add(Plane3d::new(Vec3::Y, Vec2::ONE))),
//         MeshMaterial3d(materials.add(StandardMaterial {
//             emissive: PURPLE.into(),
//             ..default()
//         })),
//         Transform::from_xyz(-2.6, -1.2, -2.6),
//     ));
// }

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

    info!("** populate_simu_plane_and_images **");

    let mut image = Image::new_fill(
        Extent3d {
            width: SIMU_SIZE.0,
            height: SIMU_SIZE.1,
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
            emissive_texture: Some(image_a.clone()),
            ..default()
        })),
        Transform::from_xyz(-2.6, -1.2, -2.6),
    ));

    // commands.spawn((
    //     Mesh3d(
    //         meshes.add(
    //             Plane3d::default()
    //                 .mesh()
    //                 .size(400.0, 400.0)
    //                 .subdivisions(20),
    //         ),
    //     ),
    //     MeshMaterial3d(materials.add(StandardMaterial {
    //         perceptual_roughness: 1.0,
    //         metallic: 0.0,
    //         base_color_texture: Some(image_a.clone()),
    //         ..StandardMaterial::default()
    //     })),
    //     Transform::from_xyz(100.0, -0.25, -100.0),
    //     SimuSettings::default(),
    // ));

    // // insert images
    // commands.insert_resource(SimuImages { image_a, image_b });
}
