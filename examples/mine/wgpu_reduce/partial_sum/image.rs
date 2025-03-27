use super::debug_material::DebugMaterial;

use super::consts::TEXTURE_FORMAT;
use super::consts::TEXTURE_SIZE;
use super::PartialSumSettings;

use bevy::prelude::*;
use bevy::render::extract_resource::ExtractResource;
use bevy::render::render_asset::RenderAssetUsages;

//////////////////////////////////////////////////////////////////////

#[derive(Resource, ExtractResource, Clone)]
pub struct PartialSumImages {
    pub image_initial: Handle<Image>,
    pub image_current: Handle<Image>,
}

pub fn populate_planes(
    mut commands: Commands,
    mut images: ResMut<Assets<Image>>,
    mut meshes: ResMut<Assets<Mesh>>,
    mut materials: ResMut<Assets<DebugMaterial>>,
    // mut warped_materials: ResMut<Assets<WarpedMaterial>>,
    // mut displaced_materials: ResMut<Assets<DisplacedMaterial>>,
    // asset_server: Res<AssetServer>,
) {
    use bevy::render::render_resource::*;

    info!("** populate_plane **");

    let mut image = Image::new_fill(
        Extent3d {
            width: TEXTURE_SIZE.0,
            height: TEXTURE_SIZE.1,
            depth_or_array_layers: 1,
        },
        TextureDimension::D2,
        &[0, 0],
        TEXTURE_FORMAT,
        RenderAssetUsages::RENDER_WORLD,
    );
    image.texture_descriptor.usage =
        TextureUsages::COPY_DST | TextureUsages::STORAGE_BINDING | TextureUsages::TEXTURE_BINDING;
    image.sampler = bevy::image::ImageSampler::nearest();

    let image_initial = images.add(image.clone());
    let image_current = images.add(image);

    let plane = meshes.add(Plane3d::default());

    // magic planes
    commands
        .spawn((
            PartialSumSettings {
                seed: 0x1fb474bf,
                count: 0,
            },
            Transform::default(),
            InheritedVisibility::VISIBLE,
        ))
        .with_children(|parent| {
            parent.spawn((
                Mesh3d(plane.clone()),
                MeshMaterial3d(materials.add(DebugMaterial {
                    data_texture: image_initial.clone(),
                })),
                Transform::from_xyz(-0.5, 0.0, 0.0),
            ));
            parent.spawn((
                Mesh3d(plane.clone()),
                MeshMaterial3d(materials.add(DebugMaterial {
                    data_texture: image_current.clone(),
                })),
                Transform::from_xyz(0.5, 0.0, 0.0),
            ));
        });

    /*
    let image_voronoi = asset_server.load::<Image>("textures/voronoi.png");
    commands.spawn((
        Mesh3d(meshes.add(Plane3d::new(Vec3::Y, Vec2::ONE))),
        MeshMaterial3d(warped_materials.add(WarpedMaterial::new(
            image_voronoi.clone(),
            image_pattern.clone(),
        ))),
        Transform::from_xyz(3.0, 0.0, -1.0),
    ));

    commands.spawn((
        Mesh3d(meshes.add(make_cubes_mesh(256, 0.01))),
        MeshMaterial3d(displaced_materials.add(DisplacedMaterial::new(image_pattern.clone()))),
        Transform::from_xyz(-4.0, 1e-2, -2.0),
    ));
    */

    // insert images
    commands.insert_resource(PartialSumImages {
        image_initial,
        image_current,
    });
}

/*
fn make_cubes_mesh(num_points: u32, half_width: f32) -> Mesh {
    use bevy::render::mesh::Indices;
    use bevy::render::mesh::Mesh;
    use bevy::render::render_asset::RenderAssetUsages;
    use bevy::render::render_resource::PrimitiveTopology;

    let mut vertices: Vec<Vec3> = vec![];
    let mut normals: Vec<Vec3> = vec![];
    let mut indices: Vec<u32> = vec![];
    for _ in 0..num_points {
        let ii = vertices.len() as u32;
        vertices.push(Vec3::new(-half_width, 0.0, -half_width));
        vertices.push(Vec3::new(half_width, 0.0, -half_width));
        vertices.push(Vec3::new(half_width, 0.0, half_width));
        vertices.push(Vec3::new(-half_width, 0.0, half_width));
        normals.push(Vec3::Y);
        normals.push(Vec3::Y);
        normals.push(Vec3::Y);
        normals.push(Vec3::Y);
        indices.extend([ii, ii + 2, ii + 1]);
        indices.extend([ii, ii + 3, ii + 2]);
    }

    Mesh::new(
        PrimitiveTopology::TriangleList,
        RenderAssetUsages::MAIN_WORLD | RenderAssetUsages::RENDER_WORLD,
    )
    .with_inserted_attribute(Mesh::ATTRIBUTE_POSITION, vertices)
    .with_inserted_attribute(Mesh::ATTRIBUTE_NORMAL, normals)
    .with_inserted_indices(Indices::U32(indices))
}
*/
