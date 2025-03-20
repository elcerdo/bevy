//! headless wgpu pipeline cli

use bevy::app::plugin_group;
use bevy::prelude::*;

plugin_group! {
    pub struct CliPlugins {
        bevy::log:::LogPlugin,
        bevy::app:::TaskPoolPlugin,
        bevy::time:::TimePlugin,
        // bevy::diagnostic:::FrameCountPlugin,
    }
}

fn main() {
    let mut app = App::new();

    app.add_plugins(CliPlugins);

    app.add_systems(Startup, setup);

    app.run();
}

fn setup() {
    warn!("hello world");
}
