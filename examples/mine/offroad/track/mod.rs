use crate::global_state::{GlobalState, TrackNickname};

use bevy::asset::{AssetServer, Assets};
use bevy::color::Srgba;
use bevy::math::{Affine2, Vec2};
use bevy::pbr::{StandardMaterial, UvChannel};
use bevy::render::mesh::Mesh;

use bevy::prelude::info;
use bevy::prelude::NextState;
use bevy::prelude::{Commands, Handle, Res, ResMut, Transform};
use bevy::prelude::{Component, Entity, Query, With};
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
pub const TRACK_GROUND_COLOR: Srgba = bevy::color::palettes::basic::SILVER;
const EPSILON: f32 = 5e-2;

//////////////////////////////////////////////////////////////////////

pub struct TrackPlugin;

impl bevy::prelude::Plugin for TrackPlugin {
    fn build(&self, app: &mut bevy::prelude::App) {
        use bevy::prelude::*;
        app.init_asset::<Track>();
        app.add_plugins(MaterialPlugin::<RacingLineMaterial>::default());
        app.add_systems(PreStartup, data::prepare_tracks);
        app.add_systems(
            OnEnter(GlobalState::TrackSelected(TrackNickname::Advanced)),
            (
                populate_advanced_track_and_checkpoints,
                populate_advanced_overlay,
                exit_to_in_game,
            )
                .chain(),
        );
        app.add_systems(OnEnter(GlobalState::InGame), populate_camera_and_lights);
        app.add_systems(OnExit(GlobalState::InGame), depopulate_all);
        app.add_systems(
            Update,
            (racing_line_material::animate, wavy_material::animate)
                .run_if(in_state(GlobalState::InGame)),
        );
    }
}

//////////////////////////////////////////////////////////////////////

// const TRACK_BEGINNER_TRANSFORM: Transform = Transform::from_xyz(22.0, 0.0, -14.0);
// const TRACK_VERTICAL_TRANSFORM_AA: Transform = Transform::from_xyz(-1.0, 0.0, -8.0);
// const TRACK_VERTICAL_TRANSFORM_BB: Transform = Transform {
//     translation: Vec3::new(12.0, 0.0, 9.0),
//     rotation: Quat::from_xyzw(-0.70710677, -0.0, -0.0, 0.70710677),
//     scale: Vec3::ONE,
// };

#[derive(Component)]
struct GameSceneMarker;

fn depopulate_all(mut commands: Commands, query: Query<Entity, With<GameSceneMarker>>) {
    for entity in query {
        commands.entity(entity).despawn();
    }
}

fn populate_camera_and_lights(mut commands: Commands) {
    use bevy::prelude::*;
    use bevy::render::camera::ScalingMode;

    info!("** populate_camera_and_lights **");

    // lights
    commands.spawn((
        GameSceneMarker,
        PointLight {
            shadows_enabled: true,
            intensity: 5.0e6,
            range: 100.0,
            shadow_depth_bias: 0.2,
            ..default()
        },
        Transform::from_xyz(-4.0, 16.0, 8.0),
    ));
    commands.spawn((
        GameSceneMarker,
        DirectionalLight {
            color: Color::WHITE,
            shadows_enabled: true,
            illuminance: light_consts::lux::OVERCAST_DAY,
            ..default()
        },
        Transform::from_translation(Vec3::Y).looking_at(vec3(-1.0, 0.0, -1.0), Vec3::Y),
    ));

    // camera
    commands.spawn((
        GameSceneMarker,
        Camera3d::default(),
        Projection::from(OrthographicProjection {
            scaling_mode: ScalingMode::FixedVertical {
                viewport_height: 14.0,
            },
            ..OrthographicProjection::default_3d()
        }),
        Transform::from_xyz(-10.0, 10.0, 15.0).looking_at(Vec3::ZERO, Vec3::Y),
    ));
}

fn populate_advanced_track_and_checkpoints(
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
    use bevy::prelude::*;
    use wavy_material::AnimatedWavyMarker;

    let make_tileable = |settings: &mut ImageLoaderSettings| -> () {
        *settings = ImageLoaderSettings {
            is_srgb: false,
            sampler: ImageSampler::Descriptor(ImageSamplerDescriptor {
                address_mode_u: ImageAddressMode::Repeat,
                address_mode_v: ImageAddressMode::Repeat,
                ..ImageSamplerDescriptor::default()
            }),
            ..ImageLoaderSettings::default()
        }
    };

    info!("** populate_advanced_track_and_checkpoints **");

    let track = tracks.get(&data::TRACK_ADVANCED_HANDLE).unwrap();

    // materials
    let checkpoint_material = materials.add(StandardMaterial {
        base_color: Color::hsva(0.0, 0.8, 1.0, 0.8),
        ..StandardMaterial::default()
    });
    let wavy_material = materials.add(wavy_material::make(&asset_server, 0.6, PI / 3.0));
    let _checkerboard_material = materials.add(StandardMaterial {
        base_color_channel: UvChannel::Uv1,
        base_color_texture: Some(
            asset_server.load_with_settings("textures/uv_checker_bw.png", make_tileable),
        ),
        uv_transform: Affine2::from_scale(Vec2::new(1.0 / 8.0, 1.0 / 8.0)),
        ..StandardMaterial::default()
    });
    let _tiledflow_material = materials.add(StandardMaterial {
        base_color_channel: UvChannel::Uv0,
        base_color_texture: Some(asset_server.load_with_settings(
            "textures/fantasy_ui_borders/panel-border-010.png",
            make_tileable,
        )),
        ..StandardMaterial::default()
    });

    // ground plane
    commands.spawn((
        GameSceneMarker,
        Mesh3d(meshes.add(Plane3d::default().mesh().size(50.0, 50.0).subdivisions(20))),
        MeshMaterial3d(materials.add(Color::from(TRACK_GROUND_COLOR))),
        Transform::from_xyz(0.0, -EPSILON, 0.0),
    ));

    // checkpoints
    commands.spawn((
        GameSceneMarker,
        Mesh3d(meshes.add(track.checkpoint.clone())),
        MeshMaterial3d(checkpoint_material.clone()),
        Transform::from_translation(2.0 * EPSILON * track.initial_up),
    ));

    // track
    commands.spawn((
        GameSceneMarker,
        Mesh3d(meshes.add(track.track.clone())),
        AnimatedWavyMarker,
        MeshMaterial3d(wavy_material.clone()),
        // MeshMaterial3d(_checkerboard_material.clone()),
        // MeshMaterial3d(_tiledflow_material.clone()),
    ));
}

fn populate_advanced_overlay(
    mut commands: Commands,
    mut meshes: ResMut<Assets<Mesh>>,
    mut materials: ResMut<Assets<RacingLineMaterial>>,
    tracks: Res<Assets<Track>>,
    asset_server: Res<AssetServer>,
) {
    use racing_line_material::AnimatedRacingLineMarker;

    info!("** populate_advanced_overlay **");

    let track = tracks.get(&data::TRACK_ADVANCED_HANDLE).unwrap();

    let mut overlay_material = racing_line_material::make(&asset_server, track.total_length);
    overlay_material.middle_line_width = -1.0; // no middle line
    overlay_material.lateral_range = Vec2::new(-1.5, 1.5);
    commands.spawn((
        GameSceneMarker,
        AnimatedRacingLineMarker,
        Mesh3d(meshes.add(track.track.clone())),
        MeshMaterial3d(materials.add(overlay_material)),
        Transform::from_translation(2.0 * EPSILON * track.initial_up),
    ));
}

fn exit_to_in_game(mut next_state: ResMut<NextState<GlobalState>>) {
    next_state.set(GlobalState::InGame);
}
