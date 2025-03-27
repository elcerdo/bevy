//! headless wgpu pipeline cli

mod camera;
mod partial_sum;

use bevy::prelude::*;

fn main() {
    let mut app = App::new();

    app.add_plugins(DefaultPlugins);
    app.add_plugins(camera::CameraPlugin);
    app.add_plugins(partial_sum::PartialSumPlugin);

    app.add_systems(Startup, setup);
    app.add_systems(Update, keyboard_shortcuts);

    app.run();
}

fn setup() {
    warn!("hello world");
}

fn hash(value: u32) -> u32 {
    let mut state = value;
    state ^= 2747636419;
    state *= 2654435769;
    state ^= state >> 16;
    state *= 2654435769;
    state ^= state >> 16;
    state *= 2654435769;
    state
}

fn keyboard_shortcuts(
    mut settings: Single<&mut partial_sum::PartialSumSettings>,
    mut triggers: ResMut<partial_sum::PartialSumTriggers>,
    mut writer: EventWriter<AppExit>,
    keyboard: Res<ButtonInput<KeyCode>>,
) {
    if keyboard.just_pressed(KeyCode::Escape) {
        writer.write(AppExit::Success);
    }
    if keyboard.just_pressed(KeyCode::Tab) {
        triggers.should_reinit = true;
    }
    if keyboard.just_pressed(KeyCode::Space) {
        warn!("reseed");
        settings.seed = hash(settings.seed);
        triggers.should_reinit = true;
    }
}
