mod debug_material;

mod bind;
mod consts;
mod image;
mod node;
mod pipeline;

use bevy::prelude::*;
use bevy::render::extract_component::ExtractComponent;
use bevy::render::extract_component::ExtractComponentPlugin;
use bevy::render::extract_component::UniformComponentPlugin;
use bevy::render::extract_resource::ExtractResource;
use bevy::render::extract_resource::ExtractResourcePlugin;
use bevy::render::graph::CameraDriverLabel;
use bevy::render::render_graph::{RenderGraph, RenderLabel};
use bevy::render::render_resource::ShaderType;
use bevy::render::{Render, RenderApp, RenderSet};

//////////////////////////////////////////////////////////////////////

#[derive(Component, ExtractComponent, Clone, ShaderType, Debug)]
pub struct PartialSumSettings {
    count: u32,
    pub seed: u32,
}

#[derive(Resource, ExtractResource, Clone, Default)]
pub struct PartialSumTriggers {
    pub should_reinit: bool,
}

//////////////////////////////////////////////////////////////////////

#[derive(Hash, Clone, Eq, PartialEq, Debug, RenderLabel)]
struct PartialSumMainNode;

pub struct PartialSumPlugin;

impl Plugin for PartialSumPlugin {
    fn build(&self, app: &mut App) {
        // sync between main and render app
        app.add_plugins((
            ExtractComponentPlugin::<PartialSumSettings>::default(),
            UniformComponentPlugin::<PartialSumSettings>::default(),
        ));

        // main app
        app.add_plugins(MaterialPlugin::<debug_material::DebugMaterial>::default());
        app.add_plugins(ExtractResourcePlugin::<image::PartialSumImages>::default());
        app.add_plugins(ExtractResourcePlugin::<PartialSumTriggers>::default());
        app.add_systems(Startup, image::populate_planes);

        // render app
        let render_app = app.sub_app_mut(RenderApp);
        render_app.add_systems(ExtractSchedule, bind::increment_count);
        render_app.add_systems(
            Render,
            bind::prepare_bind_groups.in_set(RenderSet::PrepareBindGroups),
        );
        let mut render_graph = render_app.world_mut().resource_mut::<RenderGraph>();
        render_graph.add_node(PartialSumMainNode, node::MainNode::default());
        render_graph.add_node_edge(PartialSumMainNode, CameraDriverLabel);
    }
    fn finish(&self, app: &mut App) {
        // main app
        app.init_resource::<PartialSumTriggers>();

        // render app
        let render_app = app.sub_app_mut(RenderApp);
        render_app.init_resource::<pipeline::PartialSumPipeline>();
    }
}

//////////////////////////////////////////////////////////////////////
