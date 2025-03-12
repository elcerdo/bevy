mod bind;
mod consts;
mod image;
mod node;
mod pipeline;

use image::AdvectionImages;
use image::AdvectionSettings;
use node::MainNode;
use pipeline::AdvectionPipeline;

pub use pipeline::AdvectionTriggers;

use bevy::prelude::*;
use bevy::render::extract_component::ExtractComponentPlugin;
use bevy::render::extract_component::UniformComponentPlugin;
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
        // sync between main and render app
        app.add_plugins((
            ExtractComponentPlugin::<AdvectionSettings>::default(),
            UniformComponentPlugin::<AdvectionSettings>::default(),
        ));

        // main app
        app.add_plugins(ExtractResourcePlugin::<AdvectionImages>::default());
        app.add_plugins(ExtractResourcePlugin::<AdvectionTriggers>::default());
        app.add_systems(Startup, image::populate_plane_and_images);

        // render app
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
        // main app
        app.init_resource::<AdvectionTriggers>();

        // render app
        let render_app = app.sub_app_mut(RenderApp);
        render_app.init_resource::<AdvectionPipeline>();
    }
}
