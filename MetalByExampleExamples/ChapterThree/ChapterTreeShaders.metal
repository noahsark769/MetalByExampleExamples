//
//  ChapterTwoShaders.metal
//  MetalByExampleExamples
//
//  Created by Noah Gilmore on 10/27/19.
//  Copyright © 2019 Noah Gilmore. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct ChapterThreeVertexInOut {
    /// Position of the vertex
    float4 position [[position]];

    /// Color of the vertex
    float4 color;
};

vertex ChapterThreeVertexInOut chapter_three_vertex_shader(device ChapterThreeVertexInOut *vertices [[buffer(0)]],
                                                       uint vertexId [[vertex_id]])
{
    return vertices[vertexId];
}

fragment float4 chapter_three_fragment_shader(ChapterThreeVertexInOut inVertex [[stage_in]]) {
    return inVertex.color;
}
