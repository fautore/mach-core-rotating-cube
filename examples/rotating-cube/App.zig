const std = @import("std");
const mach = @import("mach");
const gpu = mach.gpu;
const math = mach.math;

pub const name = .app;
pub const Mod = mach.Mod(@This());

const Vec3 = math.Vec3;
const UniformBufferObject = extern struct {
    offset: Vec3,
    scale: f32,
};

pub const systems = .{
    .init = .{ .handler = init },
    .after_init = .{ .handler = afterInit },
    .deinit = .{ .handler = deinit },
    .tick = .{ .handler = tick },
};

title_timer: mach.Timer,
pipeline: *gpu.RenderPipeline,
vertex_buffer: *gpu.Buffer,
uniform_buffer: *gpu.Buffer,
bind_group: *gpu.BindGroup,

pub const Vertex = extern struct {
    pos: @Vector(4, f32),
    col: @Vector(4, f32),
    uv: @Vector(2, f32),
};

pub const vertices = [_]Vertex{
    .{ .pos = .{ 1, -1, 1, 1 }, .col = .{ 1, 0, 1, 1 }, .uv = .{ 1, 1 } },
    .{ .pos = .{ -1, -1, 1, 1 }, .col = .{ 0, 0, 1, 1 }, .uv = .{ 0, 1 } },
    .{ .pos = .{ -1, -1, -1, 1 }, .col = .{ 0, 0, 0, 1 }, .uv = .{ 0, 0 } },
    .{ .pos = .{ 1, -1, -1, 1 }, .col = .{ 1, 0, 0, 1 }, .uv = .{ 1, 0 } },
    .{ .pos = .{ 1, -1, 1, 1 }, .col = .{ 1, 0, 1, 1 }, .uv = .{ 1, 1 } },
    .{ .pos = .{ -1, -1, -1, 1 }, .col = .{ 0, 0, 0, 1 }, .uv = .{ 0, 0 } },

    .{ .pos = .{ 1, 1, 1, 1 }, .col = .{ 1, 1, 1, 1 }, .uv = .{ 1, 1 } },
    .{ .pos = .{ 1, -1, 1, 1 }, .col = .{ 1, 0, 1, 1 }, .uv = .{ 0, 1 } },
    .{ .pos = .{ 1, -1, -1, 1 }, .col = .{ 1, 0, 0, 1 }, .uv = .{ 0, 0 } },
    .{ .pos = .{ 1, 1, -1, 1 }, .col = .{ 1, 1, 0, 1 }, .uv = .{ 1, 0 } },
    .{ .pos = .{ 1, 1, 1, 1 }, .col = .{ 1, 1, 1, 1 }, .uv = .{ 1, 1 } },
    .{ .pos = .{ 1, -1, -1, 1 }, .col = .{ 1, 0, 0, 1 }, .uv = .{ 0, 0 } },

    .{ .pos = .{ -1, 1, 1, 1 }, .col = .{ 0, 1, 1, 1 }, .uv = .{ 1, 1 } },
    .{ .pos = .{ 1, 1, 1, 1 }, .col = .{ 1, 1, 1, 1 }, .uv = .{ 0, 1 } },
    .{ .pos = .{ 1, 1, -1, 1 }, .col = .{ 1, 1, 0, 1 }, .uv = .{ 0, 0 } },
    .{ .pos = .{ -1, 1, -1, 1 }, .col = .{ 0, 1, 0, 1 }, .uv = .{ 1, 0 } },
    .{ .pos = .{ -1, 1, 1, 1 }, .col = .{ 0, 1, 1, 1 }, .uv = .{ 1, 1 } },
    .{ .pos = .{ 1, 1, -1, 1 }, .col = .{ 1, 1, 0, 1 }, .uv = .{ 0, 0 } },

    .{ .pos = .{ -1, -1, 1, 1 }, .col = .{ 0, 0, 1, 1 }, .uv = .{ 1, 1 } },
    .{ .pos = .{ -1, 1, 1, 1 }, .col = .{ 0, 1, 1, 1 }, .uv = .{ 0, 1 } },
    .{ .pos = .{ -1, 1, -1, 1 }, .col = .{ 0, 1, 0, 1 }, .uv = .{ 0, 0 } },
    .{ .pos = .{ -1, -1, -1, 1 }, .col = .{ 0, 0, 0, 1 }, .uv = .{ 1, 0 } },
    .{ .pos = .{ -1, -1, 1, 1 }, .col = .{ 0, 0, 1, 1 }, .uv = .{ 1, 1 } },
    .{ .pos = .{ -1, 1, -1, 1 }, .col = .{ 0, 1, 0, 1 }, .uv = .{ 0, 0 } },

    .{ .pos = .{ 1, 1, 1, 1 }, .col = .{ 1, 1, 1, 1 }, .uv = .{ 1, 1 } },
    .{ .pos = .{ -1, 1, 1, 1 }, .col = .{ 0, 1, 1, 1 }, .uv = .{ 0, 1 } },
    .{ .pos = .{ -1, -1, 1, 1 }, .col = .{ 0, 0, 1, 1 }, .uv = .{ 0, 0 } },
    .{ .pos = .{ -1, -1, 1, 1 }, .col = .{ 0, 0, 1, 1 }, .uv = .{ 0, 0 } },
    .{ .pos = .{ 1, -1, 1, 1 }, .col = .{ 1, 0, 1, 1 }, .uv = .{ 1, 0 } },
    .{ .pos = .{ 1, 1, 1, 1 }, .col = .{ 1, 1, 1, 1 }, .uv = .{ 1, 1 } },

    .{ .pos = .{ 1, -1, -1, 1 }, .col = .{ 1, 0, 0, 1 }, .uv = .{ 1, 1 } },
    .{ .pos = .{ -1, -1, -1, 1 }, .col = .{ 0, 0, 0, 1 }, .uv = .{ 0, 1 } },
    .{ .pos = .{ -1, 1, -1, 1 }, .col = .{ 0, 1, 0, 1 }, .uv = .{ 0, 0 } },
    .{ .pos = .{ 1, 1, -1, 1 }, .col = .{ 1, 1, 0, 1 }, .uv = .{ 1, 0 } },
    .{ .pos = .{ 1, -1, -1, 1 }, .col = .{ 1, 0, 0, 1 }, .uv = .{ 1, 1 } },
    .{ .pos = .{ -1, 1, -1, 1 }, .col = .{ 0, 1, 0, 1 }, .uv = .{ 0, 0 } },
};

fn init(game: *Mod, core: *mach.Core.Mod) !void {
    core.schedule(.init);
    game.schedule(.after_init);
}

fn afterInit(game: *Mod, core: *mach.Core.Mod) !void {
    const shader_module = core.state().device.createShaderModuleWGSL("shader.wgsl", @embedFile("shader.wgsl"));
    defer shader_module.release();

    const vertex_attributes = [_]gpu.VertexAttribute{
        .{ .format = .float32x4, .offset = @offsetOf(Vertex, "pos"), .shader_location = 0 },
        .{ .format = .float32x2, .offset = @offsetOf(Vertex, "uv"), .shader_location = 1 },
    };
    const vertex_buffer_layout = gpu.VertexBufferLayout.init(.{
        .array_stride = @sizeOf(Vertex),
        .step_mode = .vertex,
        .attributes = &vertex_attributes,
    });

    const blend = gpu.BlendState{};
    const color_target = gpu.ColorTargetState{
        .format = core.get(core.state().main_window, .framebuffer_format).?,
        .blend = &blend,
    };

    const fragment = gpu.FragmentState.init(.{
        .module = shader_module,
        .entry_point = "frag_main",
        .targets = &.{color_target},
    });
    const vertex = gpu.VertexState.init(.{
        .module = shader_module,
        .entry_point = "vertex_main",
        .buffers = &.{vertex_buffer_layout},
    });

    const bgle = gpu.BindGroupLayout.Entry.buffer(0, .{ .vertex = true }, .uniform, true, 0);
    const bgl = core.state().device.createBindGroupLayout(
        &gpu.BindGroupLayout.Descriptor.init(.{
            .entries = &.{bgle},
        }),
    );
    const bind_group_layouts = [_]*gpu.BindGroupLayout{bgl};
    const pipeline_layout = core.state().device.createPipelineLayout(&gpu.PipelineLayout.Descriptor.init(.{
        .bind_group_layouts = &bind_group_layouts,
    }));

    const label = @tagName(name) ++ ".init";
    const pipeline_descriptor = gpu.RenderPipeline.Descriptor{
        .label = label,
        .fragment = &fragment,
        .layout = pipeline_layout,
        .vertex = vertex,
        .primitive = .{
            .cull_mode = .back,
        },
    };

    const vertex_buffer = core.state().device.createBuffer(&.{
        .usage = .{ .vertex = true },
        .size = @sizeOf(Vertex) * vertices.len,
        .mapped_at_creation = .true,
    });
    const vertex_mapped = vertex_buffer.getMappedRange(Vertex, 0, vertices.len);
    @memcpy(vertex_mapped.?, vertices[0..]);
    vertex_buffer.unmap();

    const uniform_buffer = core.state().device.createBuffer(&.{
        .usage = .{ .copy_dst = true, .uniform = true },
        .size = @sizeOf(UniformBufferObject),
        .mapped_at_creation = .false,
    });
    const bind_group = core.state().device.createBindGroup(
        &gpu.BindGroup.Descriptor.init(.{
            .layout = bgl,
            .entries = &.{gpu.BindGroup.Entry.buffer(0, uniform_buffer, 0, @sizeOf(UniformBufferObject), @sizeOf(UniformBufferObject))},
        }),
    );

    const pipeline = core.state().device.createRenderPipeline(&pipeline_descriptor);
    game.init(.{
        .title_timer = try mach.Timer.start(),
        .pipeline = pipeline,
        .bind_group = bind_group,
        .vertex_buffer = vertex_buffer,
        .uniform_buffer = uniform_buffer,
    });
    core.schedule(.start);
}

fn tick(core: *mach.Core.Mod, game: *Mod) !void {
    var iter = mach.core.pollEvents();
    while (iter.next()) |event| {
        switch (event) {
            .close => core.schedule(.exit),
            else => std.debug.print("{}", .{event}),
        }
    }
    const back_buffer_view = mach.core.swap_chain.getCurrentTextureView().?;
    defer back_buffer_view.release();

    const label = @tagName(name) ++ ".tick";
    const encoder = core.state().device.createCommandEncoder(&.{
        .label = label,
    });
    defer encoder.release();

    const sky_blue_background = gpu.Color{ .r = 0.776, .g = 0.988, .b = 1, .a = 1 };
    const color_attachments = [_]gpu.RenderPassColorAttachment{.{
        .view = back_buffer_view,
        .clear_value = sky_blue_background,
        .load_op = .clear,
        .store_op = .store,
    }};

    {
        const time = game.state().title_timer.read();
        var transform = math.Mat4x4.ident;
        transform = transform.mul(&math.Mat4x4.rotateX(time * (std.math.pi / 2.0)));
        transform = transform.mul(&math.Mat4x4.rotateZ(time * (std.math.pi / 2.0)));
        const view = math.Mat4x4.ident;
        //    zm.Vec{ 0, 4, 2, 1 },
        //    zm.Vec{ 0, 0, 0, 1 },
        //    zm.Vec{ 0, 0, 1, 0 },
        //);
        const descriptor_width = core.get(core.state().main_window, .framebuffer_width).?;
        const descriptor_height = core.get(core.state().main_window, .framebuffer_height).?;
        const proj = math.Mat4x4.projection3D(.{
            .fov = (std.math.pi / 4.0),
            .aspect = @as(f32, @floatFromInt(descriptor_width)) / @as(f32, @floatFromInt(descriptor_height)),
            .near = 0.1,
            .far = 10,
        });

        const mvp = math.mul(math.mul(transform, view), proj);
        const ubo = UniformBufferObject{
            .mat = math.transpose(mvp),
        };
        core.state().queue.writeBuffer(game.state().uniform_buffer, 0, &[_]UniformBufferObject{ubo});
    }

    const render_pass = encoder.beginRenderPass(&gpu.RenderPassDescriptor.init(.{
        .label = label,
        .color_attachments = &color_attachments,
    }));
    defer render_pass.release();

    render_pass.setPipeline(game.state().pipeline);
    render_pass.setVertexBuffer(0, game.state().vertex_buffer, 0, @sizeOf(Vertex) * vertices.len);
    render_pass.setBindGroup(0, game.state().bind_group, &.{0});
    render_pass.draw(vertices.len, 1, 0, 0);
    render_pass.end();

    var command = encoder.finish(&.{ .label = label });
    defer command.release();
    core.state().queue.submit(&[_]*gpu.CommandBuffer{command});

    // Present the frame
    core.schedule(.present_frame);

    // update the window title every second
    if (game.state().title_timer.read() >= 1.0) {
        game.state().title_timer.reset();
    }
}

fn deinit(core: *mach.Core.Mod, _: *Mod) void {
    std.debug.print("Goodbye, world!", .{});
    //game.state().pipeline.release();
    core.schedule(.deinit);
}
