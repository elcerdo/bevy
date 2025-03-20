use bevy::input::mouse::AccumulatedMouseMotion;
use bevy::input::mouse::MouseScrollUnit;
use bevy::input::mouse::MouseWheel;
use bevy::prelude::*;

use std::f32::consts::PI;

//////////////////////////////////////////////////////////////////////

const CAMERA_REST_POSITION: Vec3 = vec3(1.2, 1.0, -1.2);

pub struct CameraPlugin;

impl Plugin for CameraPlugin {
    fn build(&self, app: &mut App) {
        app.add_systems(Startup, populate_camera);
        app.add_systems(Update, (zoom_camera, rotate_camera, reset_camera).chain());
    }
}

//////////////////////////////////////////////////////////////////////

#[derive(Component)]
struct CameraPivot {
    sensitivity: f32,
}

impl CameraPivot {
    fn default() -> Self {
        Self { sensitivity: 200.0 }
    }
}

fn populate_camera(mut commands: Commands, _asset_server: Res<AssetServer>) {
    info!("** populate_camera_and_lights **");

    // camera with envmap
    commands
        .spawn((
            Transform::from_translation(Vec3::ZERO),
            CameraPivot::default(),
            InheritedVisibility::VISIBLE,
        ))
        .with_child((
            Transform::from_translation(CAMERA_REST_POSITION).looking_at(Vec3::ZERO, Vec3::Y),
            Camera3d::default(),
            // EnvironmentMapLight {
            //     diffuse_map: asset_server.load("environment_maps/pisa_diffuse_rgb9e5_zstd.ktx2"),
            //     specular_map: asset_server.load("environment_maps/pisa_specular_rgb9e5_zstd.ktx2"),
            //     intensity: 1e3,
            //     ..default()
            // },
        ));
}

fn reset_camera(
    query: Single<&mut Transform, (With<CameraPivot>, Without<Camera3d>)>,
    query_: Single<&mut Transform, (With<Camera3d>, Without<CameraPivot>)>,
    keyboard: Res<ButtonInput<KeyCode>>,
) {
    let mut transform = query.into_inner();
    let mut transform_ = query_.into_inner();
    if keyboard.just_pressed(KeyCode::KeyR) {
        transform.rotation = Quat::IDENTITY;
        transform_.translation = CAMERA_REST_POSITION;
    }
}

fn zoom_camera(query: Single<&mut Transform, With<Camera3d>>, mut events: EventReader<MouseWheel>) {
    let mut transform = query.into_inner();
    for event in events.read() {
        let delta = match event.unit {
            MouseScrollUnit::Line => event.y * 1e-1,
            MouseScrollUnit::Pixel => event.y * 1e-2,
        };
        transform.translation -= CAMERA_REST_POSITION * delta;
    }
}

fn rotate_camera(
    query: Single<(&mut Transform, &CameraPivot)>,
    mouse_input: Res<ButtonInput<MouseButton>>,
    mouse_motion: Res<AccumulatedMouseMotion>,
) {
    let (mut transform, pivot) = query.into_inner();
    if mouse_input.pressed(MouseButton::Left) {
        let delta = mouse_motion.delta;
        transform.rotation *=
            Quat::from_axis_angle(Vec3::X, PI / 2.0 * delta.y / pivot.sensitivity);
        transform.rotation *=
            Quat::from_axis_angle(Vec3::Y, -PI / 2.0 * delta.x / pivot.sensitivity);
    }
}
