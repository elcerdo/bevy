mod consts;
mod debug_material;
mod image;

// mod bind;
// mod displaced_material;
// mod node;
// mod pipeline;
// mod warped_material;

use debug_material::DebugMaterial;
// pub use warped_material::WarpedMaterial;

use bevy::prelude::*;
use bevy::render::extract_component::ExtractComponent;
use bevy::render::extract_component::ExtractComponentPlugin;
use bevy::render::extract_component::UniformComponentPlugin;
use bevy::render::extract_resource::ExtractResource;
use bevy::render::extract_resource::ExtractResourcePlugin;
use bevy::render::render_resource::ShaderType;

// use bevy::render::graph::CameraDriverLabel;
// use bevy::render::render_graph::{RenderGraph, RenderLabel};
// use bevy::render::{Render, RenderApp, RenderSet};

//////////////////////////////////////////////////////////////////////

#[derive(Component, ExtractComponent, Clone, Default, ShaderType)]
pub struct PartialSumSettings {
    pub learning_rate: f32,
}

#[derive(Resource, ExtractResource, Clone, Default)]
pub struct PartialSumTriggers {
    pub should_reinit: bool,
}

// #[derive(Hash, Clone, Eq, PartialEq, Debug, RenderLabel)]
// struct PartialSumMainNode;

//////////////////////////////////////////////////////////////////////

pub struct PartialSumPlugin;

impl Plugin for PartialSumPlugin {
    fn build(&self, app: &mut App) {
        // sync between main and render app
        app.add_plugins((
            ExtractComponentPlugin::<PartialSumSettings>::default(),
            UniformComponentPlugin::<PartialSumSettings>::default(),
        ));

        // main app
        app.add_plugins(MaterialPlugin::<DebugMaterial>::default());
        app.add_plugins(ExtractResourcePlugin::<image::PartialSumImages>::default());
        app.add_plugins(ExtractResourcePlugin::<PartialSumTriggers>::default());
        app.add_systems(Startup, image::populate_plane);

        /*
        // render app
        let render_app = app.sub_app_mut(RenderApp);
        render_app.add_systems(
            Render,
            bind::prepare_bind_groups.in_set(RenderSet::PrepareBindGroups),
        );
        let mut render_graph = render_app.world_mut().resource_mut::<RenderGraph>();
        render_graph.add_node(PartialSumMainNode, node::MainNode::default());
        render_graph.add_node_edge(PartialSumMainNode, CameraDriverLabel);
        */
    }
    fn finish(&self, app: &mut App) {
        // main app
        app.init_resource::<PartialSumTriggers>();

        // // render app
        // let render_app = app.sub_app_mut(RenderApp);
        // render_app.init_resource::<pipeline::PartialSumPipeline>();
    }
}

//////////////////////////////////////////////////////////////////////
