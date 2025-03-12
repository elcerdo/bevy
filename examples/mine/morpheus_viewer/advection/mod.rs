mod bind;
mod consts;
mod image;
mod node;
mod pipeline;

use image::AdvectionImages;
use node::MainNode;
use pipeline::AdvectionPipeline;
use pipeline::AdvectionTriggers;

use bevy::prelude::*;
use bevy::render::extract_resource::ExtractResourcePlugin;
use bevy::render::graph::CameraDriverLabel;
use bevy::render::render_graph::{RenderGraph, RenderLabel};
use bevy::render::{Render, RenderApp, RenderSet};

//////////////////////////////////////////////////////////////////////

pub struct AdvectionPlugin;

#[derive(Hash, Clone, Eq, PartialEq, Debug, RenderLabel)]
enum AdvectionNodes {
    Main,
}

impl Plugin for AdvectionPlugin {
    fn build(&self, app: &mut App) {
        // app.add_plugins((
        //     // The settings will be a component that lives in the main world but will
        //     // be extracted to the render world every frame.
        //     // This makes it possible to control the effect from the main world.
        //     // This plugin will take care of extracting it automatically.
        //     // It's important to derive [`ExtractComponent`] on [`PostProcessingSettings`]
        //     // for this plugin to work correctly.
        //     ExtractComponentPlugin::<SimuSettings>::default(),
        //     // The settings will also be the data used in the shader.
        //     // This plugin will prepare the component for the GPU by creating a uniform buffer
        //     // and writing the data to that buffer every frame.
        //     UniformComponentPlugin::<SimuSettings>::default(),
        // ));

        // Extract the game of life image resource from the main world into the render world
        // for operation on by the compute shader and display on the sprite.
        app.add_plugins(ExtractResourcePlugin::<AdvectionImages>::default());
        app.add_plugins(ExtractResourcePlugin::<AdvectionTriggers>::default());
        app.add_systems(Startup, image::populate_plane_and_images);
        app.add_systems(Update, pipeline::update_triggers_keyboard);

        let render_app = app.sub_app_mut(RenderApp);
        render_app.add_systems(
            Render,
            (pipeline::copy_triggers, bind::prepare_bind_groups)
                .in_set(RenderSet::PrepareBindGroups),
        );
        let mut render_graph = render_app.world_mut().resource_mut::<RenderGraph>();
        render_graph.add_node(AdvectionNodes::Main, MainNode::default());
        render_graph.add_node_edge(AdvectionNodes::Main, CameraDriverLabel);
    }
    fn finish(&self, app: &mut App) {
        app.init_resource::<AdvectionTriggers>();

        let render_app = app.sub_app_mut(RenderApp);
        render_app.init_resource::<AdvectionPipeline>();
    }
}
