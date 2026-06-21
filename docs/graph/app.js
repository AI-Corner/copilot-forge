document.addEventListener("DOMContentLoaded", () => {
    if (typeof graphData === 'undefined') {
        console.error("graphData is not defined. Please run scripts/generate-graph.ps1 first.");
        return;
    }

    const svg = d3.select("#graph-svg");
    const container = d3.select("#main-container");
    const g = svg.append("g");
    
    // Zoom
    const zoom = d3.zoom()
        .scaleExtent([0.1, 4])
        .on("zoom", (event) => g.attr("transform", event.transform));
    svg.call(zoom);

    // Arrowhead marker
    svg.append("defs").append("marker")
        .attr("id", "arrow")
        .attr("viewBox", "0 -5 10 10")
        .attr("refX", 22)
        .attr("refY", 0)
        .attr("markerWidth", 6)
        .attr("markerHeight", 6)
        .attr("orient", "auto")
        .append("path")
        .attr("d", "M0,-5L10,0L0,5")
        .attr("fill", "#8b949e");

    let simulation, linkSelection, nodeSelection, labelSelection;
    let activeNode = null;

    // Filters
    const filterState = {
        prompt: true,
        agent: true,
        script: true,
        template: false
    };

    document.getElementById("filter-prompt").addEventListener("change", (e) => updateFilters('prompt', e.target.checked));
    document.getElementById("filter-agent").addEventListener("change", (e) => updateFilters('agent', e.target.checked));
    document.getElementById("filter-script").addEventListener("change", (e) => updateFilters('script', e.target.checked));
    document.getElementById("filter-template").addEventListener("change", (e) => updateFilters('template', e.target.checked));

    function updateFilters(type, checked) {
        filterState[type] = checked;
        renderGraph();
    }

    function renderGraph() {
        // Filter Data
        const filteredNodes = graphData.nodes.filter(n => filterState[n.group]);
        const nodeIds = new Set(filteredNodes.map(n => n.id));
        
        // Ensure links only exist if both ends are visible
        // We use the original string IDs for filtering
        const filteredLinks = graphData.links
            .filter(l => {
                const srcId = typeof l.source === 'object' ? l.source.id : l.source;
                const tgtId = typeof l.target === 'object' ? l.target.id : l.target;
                return nodeIds.has(srcId) && nodeIds.has(tgtId);
            })
            .map(l => Object.assign({}, l)); // Clone so D3 doesn't mutate original
            
        // Clone nodes
        const nodes = filteredNodes.map(n => Object.assign({}, n));

        // Clear existing
        g.selectAll("*").remove();

        // Re-add Links
        linkSelection = g.append("g").attr("class", "links")
            .selectAll("line")
            .data(filteredLinks)
            .enter().append("line")
            .attr("marker-end", "url(#arrow)")
            .style("stroke-dasharray", d => d.type === "resource" ? "5,5" : "none");

        // Re-add Nodes
        nodeSelection = g.append("g").attr("class", "nodes")
            .selectAll("circle")
            .data(nodes)
            .enter().append("circle")
            .attr("r", 12)
            .style("fill", d => {
                if (d.group === "prompt") return "#d4edda";
                if (d.group === "agent") return "#e2d9f3";
                if (d.group === "script") return "#cce5ff";
                return "#fff3cd";
            })
            .style("stroke", d => {
                if (d.group === "prompt") return "#28a745";
                if (d.group === "agent") return "#6f42c1";
                if (d.group === "script") return "#007bff";
                return "#ffc107";
            })
            .call(d3.drag()
                .on("start", dragstarted)
                .on("drag", dragged)
                .on("end", dragended))
            .on("click", onNodeClick);

        // Re-add Labels
        labelSelection = g.append("g").attr("class", "labels")
            .selectAll("text")
            .data(nodes)
            .enter().append("text")
            .attr("dy", -18)
            .attr("text-anchor", "middle")
            .text(d => d.id);

        // Run Simulation
        const width = container.node().getBoundingClientRect().width || 1200;
        const height = container.node().getBoundingClientRect().height || 800;

        if (simulation) simulation.stop();

        simulation = d3.forceSimulation(nodes)
            .force("link", d3.forceLink(filteredLinks).id(d => d.id).distance(150))
            .force("charge", d3.forceManyBody().strength(-400))
            .force("center", d3.forceCenter(width / 2, height / 2))
            .force("collide", d3.forceCollide().radius(40))
            .on("tick", () => {
                linkSelection
                    .attr("x1", d => d.source.x)
                    .attr("y1", d => d.source.y)
                    .attr("x2", d => d.target.x)
                    .attr("y2", d => d.target.y);
                nodeSelection
                    .attr("cx", d => d.x)
                    .attr("cy", d => d.y);
                labelSelection
                    .attr("x", d => d.x)
                    .attr("y", d => d.y);
            });

        // Reset state
        closeSidebar();
    }

    // Interactive Logic
    function onNodeClick(event, clickedNode) {
        event.stopPropagation();
        
        if (activeNode === clickedNode) {
            closeSidebar();
            return;
        }
        
        activeNode = clickedNode;
        openSidebar(clickedNode);

        const connectedLinks = new Set();
        const connectedNodes = new Set([clickedNode]);

        linkSelection.each(function(l) {
            if (l.source.id === clickedNode.id || l.target.id === clickedNode.id) {
                connectedLinks.add(l);
                connectedNodes.add(l.source);
                connectedNodes.add(l.target);
            }
        });

        nodeSelection.style("opacity", d => connectedNodes.has(d) ? 1 : 0.1);
        labelSelection.style("opacity", d => connectedNodes.has(d) ? 1 : 0.1);
        
        linkSelection
            .style("stroke", d => connectedLinks.has(d) ? "#58a6ff" : "#484f58")
            .style("stroke-width", d => connectedLinks.has(d) ? 3 : 1)
            .style("opacity", d => connectedLinks.has(d) ? 1 : 0.05);
            
        // Focus node
        const scale = 1.5;
        const width = container.node().getBoundingClientRect().width;
        const height = container.node().getBoundingClientRect().height;
        svg.transition().duration(750).call(
            zoom.transform, 
            d3.zoomIdentity.translate(width/2 - clickedNode.x * scale, height/2 - clickedNode.y * scale).scale(scale)
        );
    }

    // Sidebar Logic
    function openSidebar(nodeData) {
        document.getElementById("sidebar").classList.remove("hidden");
        document.getElementById("node-title").textContent = nodeData.id;
        
        const badge = document.getElementById("node-badge");
        badge.textContent = nodeData.group;
        badge.className = "badge " + nodeData.group;

        const depsOutList = document.getElementById("deps-out-list");
        const depsInList = document.getElementById("deps-in-list");
        depsOutList.innerHTML = "";
        depsInList.innerHTML = "";

        const depsOut = [];
        const depsIn = [];

        linkSelection.each(function(l) {
            if (l.source.id === nodeData.id) depsOut.push(l.target.id);
            if (l.target.id === nodeData.id) depsIn.push(l.source.id);
        });

        depsOut.sort().forEach(id => {
            const li = document.createElement("li");
            li.textContent = "→ " + id;
            li.onclick = () => jumpToNode(id);
            depsOutList.appendChild(li);
        });
        
        if (depsOut.length === 0) depsOutList.innerHTML = "<li><em>None</em></li>";

        depsIn.sort().forEach(id => {
            const li = document.createElement("li");
            li.textContent = "← " + id;
            li.onclick = () => jumpToNode(id);
            depsInList.appendChild(li);
        });
        
        if (depsIn.length === 0) depsInList.innerHTML = "<li><em>None</em></li>";
    }

    function closeSidebar() {
        activeNode = null;
        document.getElementById("sidebar").classList.add("hidden");
        linkSelection.style("stroke", "#484f58").style("stroke-width", 2).style("opacity", 1);
        nodeSelection.style("opacity", 1);
        labelSelection.style("opacity", 1);
    }
    
    function jumpToNode(id) {
        nodeSelection.each(function(d) {
            if (d.id === id) {
                onNodeClick({stopPropagation: ()=>{}}, d);
            }
        });
    }

    document.getElementById("close-sidebar").addEventListener("click", closeSidebar);
    svg.on("click", closeSidebar);

    // D3 Drag
    function dragstarted(event) {
        if (!event.active) simulation.alphaTarget(0.3).restart();
        event.subject.fx = event.subject.x;
        event.subject.fy = event.subject.y;
    }

    function dragged(event) {
        event.subject.fx = event.x;
        event.subject.fy = event.y;
    }

    function dragended(event) {
        if (!event.active) simulation.alphaTarget(0);
        event.subject.fx = null;
        event.subject.fy = null;
    }

    // Initial render
    renderGraph();
});
