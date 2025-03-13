use crate::advection::bind::AdvectionBindGroups;
use crate::advection::pipeline::AdvectionPipeline;

use bevy::prelude::*;
use bevy::render::render_graph::Node;

use crate::advection::consts::TEXTURE_SIZE;
use crate::advection::consts::WORKGROUP_SIZE;

//////////////////////////////////////////////////////////////////////

#[derive(Default)]
enum MainState {
    #[default]
    Loading,
    Init,
    Update(bool),
}

#[derive(Default)]
pub struct MainNode {
    state: MainState,
}

impl Node for MainNode {
    fn update(&mut self, world: &mut World) {
        use bevy::render::render_resource::*;

        let pipeline = world.resource::<AdvectionPipeline>();
        let pipeline_cache = world.resource::<PipelineCache>();

        let should_reinit = pipeline.triggers.should_reinit;

        // advance to next state
        match self.state {
            MainState::Loading => {
                let init_ok = matches!(
                    pipeline_cache.get_compute_pipeline_state(pipeline.init_id),
                    CachedPipelineState::Ok(_)
                );
                let update_ok = matches!(
                    pipeline_cache.get_compute_pipeline_state(pipeline.update_id),
                    CachedPipelineState::Ok(_)
                );
                if init_ok && update_ok {
                    self.state = MainState::Init;
                }
            }
            MainState::Init => {
                self.state = match should_reinit {
                    false => MainState::Update(true),
                    true => MainState::Init,
                };
            }
            MainState::Update(flipped) => {
                self.state = match should_reinit {
                    false => MainState::Update(!flipped),
                    true => MainState::Init,
                };
            }
        };
    }

    fn run(
        &self,
        _graph_context: &mut bevy::render::render_graph::RenderGraphContext,
        render_context: &mut bevy::render::renderer::RenderContext,
        world: &World,
    ) -> Result<(), bevy::render::render_graph::NodeRunError> {
        use bevy::render::render_resource::*;

        let pipeline = world.resource::<AdvectionPipeline>();
        let bind_groups = world.resource::<AdvectionBindGroups>();
        let pipeline_cache = world.resource::<PipelineCache>();

        let mut pass = render_context
            .command_encoder()
            .begin_compute_pass(&ComputePassDescriptor::default());

        // select the pipeline based on the current state
        let should_dispatch = match self.state {
            MainState::Loading => false,
            MainState::Init => {
                let init_pipeline = pipeline_cache
                    .get_compute_pipeline(pipeline.init_id)
                    .unwrap();
                pass.set_bind_group(0, &bind_groups.group_b_to_a, &[]);
                pass.set_pipeline(init_pipeline);
                true
            }
            MainState::Update(flipped) => {
                let update_pipeline = pipeline_cache
                    .get_compute_pipeline(pipeline.update_id)
                    .unwrap();
                pass.set_bind_group(
                    0,
                    if flipped {
                        &bind_groups.group_a_to_b
                    } else {
                        &bind_groups.group_b_to_a
                    },
                    &[],
                );
                pass.set_pipeline(update_pipeline);
                true
            }
        };

        if should_dispatch {
            pass.dispatch_workgroups(
                TEXTURE_SIZE.0 / WORKGROUP_SIZE,
                TEXTURE_SIZE.1 / WORKGROUP_SIZE,
                1,
            );
        }

        Ok(())
    }
}
