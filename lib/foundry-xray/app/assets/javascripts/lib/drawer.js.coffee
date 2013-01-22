#
# Dagre + D3.js wrapper
#
class @Drawer

  constructor: (@input, padding=10) ->
    @padding = padding

    @setupEntities()
    @setupEntitiesSizes()
    @draw()

  setupDagre: ->
    dagre.layout().nodeSep(50).edgeSep(10).rankSep(50)
      .nodes(@input.nodes)
      .edges(@input.edges)
      .debugLevel(1)
      .run()

  setupEntities: ->
    @svg = d3.select("svg")
    @svgGroup = @svg.append("g").attr("transform", "translate(5, 5)")

    # `nodes` is center positioned for easy layout later
    @nodes = @svgGroup.selectAll("g .node")
      .data(@input.nodes)
      .enter()
      .append("g")
      .attr("class", "node")
      #.attr("id", (d) -> "node-" + d.label)

    @edges = @svgGroup.selectAll("path .edge")
      .data(@input.edges)
      .enter()
      .append("path")
      .attr("class", "edge")
      .attr("marker-end", "url(#arrowhead)")

    # Append rectangles to the nodes. We do this before laying out the text
    # because we want the text above the rectangle.
    @rects = @nodes.append("rect")

    # Append text
    @labels = @nodes.append("text").attr("text-anchor", "middle").attr("x", 0)
    @labels.append("tspan").attr("x", 0).attr("dy", "1em").text (d) -> d.label

  setupEntitiesSizes: ->
    padding = @padding

    # We need width and height for layout.
    @labels.each (d) ->
      bbox = @getBBox()
      d.bbox = bbox
      d.width = bbox.width + 2 * padding
      d.height = bbox.height + 2 * padding

    @rects
      .attr("x", (d) -> -(d.bbox.width / 2 + padding))
      .attr("y", (d) -> -(d.bbox.height / 2 + padding))
      .attr("width", (d) -> d.width)
      .attr("height", (d) -> d.height)

    @labels
      .attr("x", (d) -> -d.bbox.width / 2)
      .attr("y", (d) -> -d.bbox.height / 2)

  draw: ->
    @setupDagre()
    @nodes.attr "transform", (d) -> "translate(" + d.dagre.x + "," + d.dagre.y + ")"

    # Ensure that we have at least two points between source and target
    @edges.each (d) ->
      points = d.dagre.points
      unless points.length
        s = d.source.dagre
        t = d.target.dagre
        points.push
          x: (s.x + t.x) / 2
          y: (s.y + t.y) / 2

      if points.length is 1
        points.push
          x: points[0].x
          y: points[0].y

    # Set the id. of the SVG element to have access to it later
    @edges.attr("id", (e) ->
      e.dagre.id
    ).attr "d", (e) ->
      points = e.dagre.points.slice(0)
      source = dagre.util.intersectRect(e.source.dagre, points[0])
      target = dagre.util.intersectRect(e.target.dagre, points[points.length - 1])
      points.unshift source
      points.push target
      d3.svg.line().x((d) ->
        d.x
      ).y((d) ->
        d.y
      ).interpolate("linear") points

    # Resize the SVG element
    svgBBox = @svg.node().getBBox()
    @svg.attr "width", svgBBox.width + 10
    @svg.attr "height", svgBBox.height + 10