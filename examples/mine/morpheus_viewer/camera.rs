use bevy::input::mouse::AccumulatedMouseMotion;
use bevy::input::mouse::MouseScrollUnit;
use bevy::input::mouse::MouseWheel;
use bevy::prelude::*;

use std::f32::consts::PI;

//////////////////////////////////////////////////////////////////////

const CAMERA_REST_SCALE: f32 = 1.5;
const CAMERA_REST_POSITION: Vec3 = vec3(
    -0.6 * CAMERA_REST_SCALE,
    0.6 * CAMERA_REST_SCALE,
    1.2 * CAMERA_REST_SCALE,
);
const CAMERA_SENSITIVITY: f32 = 200.0;
const CAMERA_RESPONSE_RATIO: f32 = 20e-2;

pub struct CameraPlugin;

impl Plugin for CameraPlugin {
    fn build(&self, app: &mut App) {
        app.add_systems(Startup, populate_camera_and_light);
        app.add_systems(Update, (zoom_camera, rotate_camera, reset_camera).chain());
    }
}

//////////////////////////////////////////////////////////////////////

#[derive(Component, Default)]
struct CameraPivot {
    target_transform: Transform,
}

fn populate_camera_and_light(mut commands: Commands, _asset_server: Res<AssetServer>) {
    info!("** populate_camera_and_light **");

    commands.spawn((
        PointLight {
            shadows_enabled: true,
            intensity: 8e6,
            range: 100.0,
            shadow_depth_bias: 0.2,
            ..default()
        },
        Transform::from_translation(Vec3::splat(20.0)),
    ));

    // camera without envmap
    commands
        .spawn((
            Transform::from_translation(Vec3::ZERO),
            CameraPivot::default(),
            InheritedVisibility::VISIBLE,
        ))
        .with_child((
            Transform::from_translation(CAMERA_REST_POSITION).looking_at(Vec3::ZERO, Vec3::Y),
            Camera3d::default(),
        ));
}

fn reset_camera(
    pivot_transform: Single<(&mut CameraPivot, &mut Transform)>,
    keyboard: Res<ButtonInput<KeyCode>>,
) {
    let (mut pivot, mut current_transform) = pivot_transform.into_inner();
    let target_transform = &mut pivot.target_transform;

    if keyboard.just_pressed(KeyCode::KeyR) {
        *target_transform = Transform::default();
        *current_transform = Transform::default();
    }
}

fn zoom_camera(
    pivot_transform: Single<(&mut CameraPivot, &mut Transform)>,
    mut events: EventReader<MouseWheel>,
) {
    let (mut pivot, mut current_transform) = pivot_transform.into_inner();
    let target_transform = &mut pivot.target_transform;

    for event in events.read() {
        let delta = 1.0
            + event.y.abs()
                * match event.unit {
                    MouseScrollUnit::Line => 1e-1,
                    MouseScrollUnit::Pixel => 1e-3,
                };
        let delta_ = if event.y > 0.0 { delta } else { 1.0 / delta };
        target_transform.scale *= delta_;
    }

    current_transform.scale = current_transform
        .scale
        .lerp(target_transform.scale, CAMERA_RESPONSE_RATIO);
}

fn rotate_camera(
    pivot_transform: Single<(&mut CameraPivot, &mut Transform)>,
    mouse_input: Res<ButtonInput<MouseButton>>,
    mouse_motion: Res<AccumulatedMouseMotion>,
) {
    let (mut pivot, mut current_transform) = pivot_transform.into_inner();
    let target_transform = &mut pivot.target_transform;

    if mouse_input.pressed(MouseButton::Left) {
        let sensitivity = CAMERA_SENSITIVITY;
        let delta = mouse_motion.delta;
        target_transform.rotation *=
            Quat::from_axis_angle(Vec3::X, -PI / 2.0 * delta.y / sensitivity);
        target_transform.rotation *=
            Quat::from_axis_angle(Vec3::Y, -PI / 2.0 * delta.x / sensitivity);
    }

    current_transform.rotation = current_transform
        .rotation
        .slerp(target_transform.rotation, CAMERA_RESPONSE_RATIO);
}
