use bevy::asset::{AssetApp, AssetServer, Assets};
use bevy::math::{Affine2, Quat, Vec2, Vec3};
use bevy::pbr::StandardMaterial;
use bevy::render::mesh::Mesh;

use bevy::prelude::info;
use bevy::prelude::{Commands, Handle, Res, ResMut, Transform};
use bevy::prelude::{Mesh3d, MeshMaterial3d};

use std::f32::consts::PI;

mod data;
mod piece;
mod racing_line_material;
mod wavy_material;

pub use piece::Segment;
pub use piece::Track;
pub use racing_line_material::RacingLineMaterial;
pub const TRACK_CURRENT_HANDLE: Handle<Track> = data::TRACK_ADVANCED_HANDLE;

//////////////////////////////////////////////////////////////////////

pub struct TrackPlugin;

impl bevy::prelude::Plugin for TrackPlugin {
    fn build(&self, app: &mut bevy::prelude::App) {
        use bevy::prelude::MaterialPlugin;
        use bevy::prelude::{PreStartup, Startup, Update};
        app.init_asset::<Track>();
        app.add_plugins(MaterialPlugin::<RacingLineMaterial>::default());
        app.add_systems(PreStartup, data::prepare_tracks);
        // app.add_systems(Startup, populate_tracks_and_checkpoints);
        // app.add_systems(Startup, populate_overlays);
        app.add_systems(Update, wavy_material::animate);
        app.add_systems(Update, racing_line_material::animate);
    }
}

//////////////////////////////////////////////////////////////////////

const TRACK_BEGINNER_TRANSFORM: Transform = Transform::from_xyz(22.0, 0.0, -14.0);
const TRACK_VERTICAL_TRANSFORM_AA: Transform = Transform::from_xyz(-1.0, 0.0, -8.0);
const TRACK_VERTICAL_TRANSFORM_BB: Transform = Transform {
    translation: Vec3::new(12.0, 0.0, 9.0),
    rotation: Quat::from_xyzw(-0.70710677, -0.0, -0.0, 0.70710677),
    scale: Vec3::ONE,
};
const TRACK_ADVANCED_TRANSFORM: Transform = Transform::from_xyz(0.0, 0.0, 0.0);

fn populate_tracks_and_checkpoints(
    mut commands: Commands,
    mut meshes: ResMut<Assets<Mesh>>,
    mut materials: ResMut<Assets<StandardMaterial>>,
    tracks: Res<Assets<Track>>,
    asset_server: Res<AssetServer>,
) {
    use bevy::color::Color;
    use bevy::image::ImageAddressMode;
    use bevy::image::ImageLoaderSettings;
    use bevy::image::ImageSampler;
    use bevy::image::ImageSamplerDescriptor;
    use bevy::pbr::UvChannel;
    use wavy_material::AnimatedWavyMarker;

    info!("** populate_tracks_and_checkpoints **");

    // tracks
    let track0 = tracks.get(&data::TRACK_BEGINNER_HANDLE).unwrap();
    let track1 = tracks.get(&data::TRACK_VERTICAL_HANDLE).unwrap();
    let track2 = tracks.get(&data::TRACK_ADVANCED_HANDLE).unwrap();

    // materials
    let wavy_material = materials.add(wavy_material::make(&asset_server, 0.6, PI / 3.0));
    let checkerboard_material = materials.add(StandardMaterial {
        base_color_channel: UvChannel::Uv1,
        base_color_texture: Some(asset_server.load_with_settings(
            "textures/uv_checker_bw.png",
            |s: &mut _| {
                *s = ImageLoaderSettings {
                    sampler: ImageSampler::Descriptor(ImageSamplerDescriptor {
                        address_mode_u: ImageAddressMode::Repeat,
                        address_mode_v: ImageAddressMode::Repeat,
                        ..ImageSamplerDescriptor::default()
                    }),
                    ..ImageLoaderSettings::default()
                }
            },
        )),
        uv_transform: Affine2::from_scale(Vec2::new(1.0 / 8.0, 1.0 / 8.0)),
        ..StandardMaterial::default()
    });
    let tiledflow_material = materials.add(StandardMaterial {
        base_color_channel: UvChannel::Uv0,
        base_color_texture: Some(asset_server.load_with_settings(
            "textures/fantasy_ui_borders/panel-border-010.png",
            |s: &mut _| {
                *s = ImageLoaderSettings {
                    sampler: ImageSampler::Descriptor(ImageSamplerDescriptor {
                        // rewriting mode to repeat image,
                        address_mode_u: ImageAddressMode::Repeat,
                        address_mode_v: ImageAddressMode::Repeat,
                        ..ImageSamplerDescriptor::default()
                    }),
                    ..ImageLoaderSettings::default()
                }
            },
        )),
        ..StandardMaterial::default()
    });
    let checkpoint_material = materials.add(StandardMaterial {
        base_color: Color::hsva(0.0, 0.8, 1.0, 0.8),
        ..StandardMaterial::default()
    });

    // beginner track showcases water effect
    commands.spawn((
        Mesh3d(meshes.add(track0.checkpoint.clone())),
        MeshMaterial3d(checkpoint_material.clone()),
        TRACK_BEGINNER_TRANSFORM,
    ));
    commands.spawn((
        AnimatedWavyMarker,
        Mesh3d(meshes.add(track0.track.clone())),
        MeshMaterial3d(wavy_material.clone()),
        TRACK_BEGINNER_TRANSFORM,
    ));

    // vertical track showcases projected parametrization wo checkpoints
    commands.spawn((
        Mesh3d(meshes.add(track1.track.clone())),
        MeshMaterial3d(checkerboard_material.clone()),
        TRACK_VERTICAL_TRANSFORM_AA,
    ));

    // transformed vertical track showcases flow parametrization wo checkpoints
    commands.spawn((
        Mesh3d(meshes.add(track1.track.clone())),
        MeshMaterial3d(tiledflow_material.clone()),
        TRACK_VERTICAL_TRANSFORM_BB,
    ));

    // advanced showcases water effect
    commands.spawn((
        Mesh3d(meshes.add(track2.checkpoint.clone())),
        MeshMaterial3d(checkpoint_material.clone()),
        TRACK_ADVANCED_TRANSFORM,
    ));
    commands.spawn((
        AnimatedWavyMarker,
        Mesh3d(meshes.add(track2.track.clone())),
        MeshMaterial3d(wavy_material.clone()),
        TRACK_ADVANCED_TRANSFORM,
    ));
}

fn populate_overlays(
    mut commands: Commands,
    mut meshes: ResMut<Assets<Mesh>>,
    mut materials: ResMut<Assets<RacingLineMaterial>>,
    tracks: Res<Assets<Track>>,
    asset_server: Res<AssetServer>,
) {
    use racing_line_material::AnimatedRacingLineMarker;

    info!("** populate_overlays **");

    // tracks
    let track0 = tracks.get(&data::TRACK_BEGINNER_HANDLE).unwrap();
    let track1 = tracks.get(&data::TRACK_VERTICAL_HANDLE).unwrap();
    let track2 = tracks.get(&data::TRACK_ADVANCED_HANDLE).unwrap();

    // showcases racing lines on beginner track
    let track3_material = racing_line_material::make(&asset_server, track0.total_length);
    let track3_transform =
        TRACK_BEGINNER_TRANSFORM * Transform::from_translation(1e-3 * track0.initial_up);
    commands.spawn((
        AnimatedRacingLineMarker,
        Mesh3d(meshes.add(track0.track.clone())),
        MeshMaterial3d(materials.add(track3_material)),
        track3_transform,
    ));

    // showcases racing lines on vertical track
    let track4_material = racing_line_material::make(&asset_server, track1.total_length);
    let track4_transform =
        TRACK_VERTICAL_TRANSFORM_AA * Transform::from_translation(1e-3 * track1.initial_up);
    commands.spawn((
        AnimatedRacingLineMarker,
        Mesh3d(meshes.add(track1.track.clone())),
        MeshMaterial3d(materials.add(track4_material)),
        track4_transform,
    ));

    // showcases racing lines on transformed vertical track
    let mut track5_material = racing_line_material::make(&asset_server, track1.total_length);
    track5_material.middle_line_width = 0.5;
    track5_material.lateral_range = Vec2::new(-1.8, 0.8);
    let track5_transform =
        TRACK_VERTICAL_TRANSFORM_BB * Transform::from_translation(1e-3 * track1.initial_up);
    commands.spawn((
        AnimatedRacingLineMarker,
        Mesh3d(meshes.add(track1.track.clone())),
        MeshMaterial3d(materials.add(track5_material)),
        track5_transform,
    ));

    // showcases non animated racing lines on advanced track
    let mut track6_material = racing_line_material::make(&asset_server, track2.total_length);
    // track5_material.middle_line_width = -1.0; // no middle line
    track6_material.lateral_range = Vec2::new(-1.5, 1.5);
    let track6_transform =
        TRACK_ADVANCED_TRANSFORM * Transform::from_translation(1e-3 * track2.initial_up);
    commands.spawn((
        Mesh3d(meshes.add(track2.track.clone())),
        MeshMaterial3d(materials.add(track6_material)),
        track6_transform,
    ));
}
