use super::bind::PartialSumBindGroups;
// use super::image::PartialSumImages;
use super::pipeline::PartialSumPipeline;
use super::PartialSumTriggers;

use super::consts::TEXTURE_SIZE;
use super::consts::WORKGROUP_SIZE;

use bevy::prelude::*;
use bevy::render::render_graph::Node;

// use bevy::render::render_asset::RenderAssets;
// use bevy::render::texture::GpuImage;

//////////////////////////////////////////////////////////////////////

#[derive(Default)]
enum MainState {
    #[default]
    Loading,
    Init,
    Reduce(u32),
    Done,
}

#[derive(Default)]
pub struct MainNode {
    state: MainState,
}

impl Node for MainNode {
    fn update(&mut self, world: &mut World) {
        use bevy::render::render_resource::*;

        let should_reinit;
        {
            let mut triggers = world.resource_mut::<PartialSumTriggers>();
            should_reinit = triggers.should_reinit;
            *triggers = PartialSumTriggers::default();
        }

        if should_reinit {
            warn!("reinit");
        }

        let cache = world.resource::<PipelineCache>();
        let pipeline = world.resource::<PartialSumPipeline>();
        // let images = world.resource::<PartialSumImages>();
        // let gpu_images = world.resource::<RenderAssets<GpuImage>>();

        // advance to next state
        match self.state {
            MainState::Loading => {
                let init_ok = matches!(
                    cache.get_compute_pipeline_state(pipeline.init_id),
                    CachedPipelineState::Ok(_)
                );
                let update_ok = matches!(
                    cache.get_compute_pipeline_state(pipeline.update_id),
                    CachedPipelineState::Ok(_)
                );
                // let voronoi_ok = gpu_images.get(&images.image_pattern).is_some();
                debug!("loading {} {}", init_ok, update_ok);
                if init_ok && update_ok {
                    self.state = MainState::Init;
                }
            }
            MainState::Init => {
                self.state = match should_reinit {
                    false => MainState::Reduce(0),
                    true => MainState::Init,
                };
            }
            MainState::Reduce(count_) => {
                let count = count_ + 1;
                self.state = match should_reinit {
                    false => {
                        if count < 8 {
                            MainState::Reduce(count)
                        } else {
                            MainState::Done
                        }
                    }
                    true => MainState::Init,
                };
            }
            MainState::Done => {
                self.state = match should_reinit {
                    false => MainState::Done,
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

        let cache = world.resource::<PipelineCache>();
        let pipeline = world.resource::<PartialSumPipeline>();
        let bind_groups = world.resource::<PartialSumBindGroups>();

        let mut pass = render_context
            .command_encoder()
            .begin_compute_pass(&ComputePassDescriptor::default());

        // select the pipeline based on the current state
        match self.state {
            MainState::Init => {
                let init_pipeline = cache.get_compute_pipeline(pipeline.init_id).unwrap();
                pass.set_bind_group(0, &bind_groups.group_b_to_a, &[]);
                pass.set_pipeline(init_pipeline);
                pass.dispatch_workgroups(
                    TEXTURE_SIZE.0 / WORKGROUP_SIZE.0,
                    TEXTURE_SIZE.1 / WORKGROUP_SIZE.1,
                    1,
                );
            }
            MainState::Reduce(count) => {
                let update_pipeline = cache.get_compute_pipeline(pipeline.update_id).unwrap();
                pass.set_bind_group(
                    0,
                    if count % 2 == 0 {
                        &bind_groups.group_a_to_b
                    } else {
                        &bind_groups.group_b_to_a
                    },
                    &[],
                );
                pass.set_pipeline(update_pipeline);
                pass.dispatch_workgroups(
                    TEXTURE_SIZE.0 / WORKGROUP_SIZE.0,
                    TEXTURE_SIZE.1 / WORKGROUP_SIZE.1,
                    1,
                );
            }
            _ => {}
        };

        Ok(())
    }
}
