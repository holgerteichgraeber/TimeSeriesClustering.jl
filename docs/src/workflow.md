## Workflow

Generally, the workflow requires three steps:
- load data
- clustering
- optimization

## CEP Specific Workflow
The input data is distinguished between time series independent and time series dependent data. They are kept separate as just the time series dependent data is used to determine representative periods (clustering).
```@raw html
<svg
   xmlns:dc="http://purl.org/dc/elements/1.1/"
   xmlns:cc="http://creativecommons.org/ns#"
   xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
   xmlns:svg="http://www.w3.org/2000/svg"
   xmlns="http://www.w3.org/2000/svg"
   xmlns:sodipodi="http://sodipodi.sourceforge.net/DTD/sodipodi-0.dtd"
   xmlns:inkscape="http://www.inkscape.org/namespaces/inkscape"
   width="120.86133mm"
   height="103.82861mm"
   viewBox="0 0 120.86134 103.82861"
   version="1.1"
   id="svg8"
   inkscape:version="0.92.3 (2405546, 2018-03-11)"
   sodipodi:docname="workflow.svg"
   inkscape:export-filename="/home/elias/workflow.png"
   inkscape:export-xdpi="299"
   inkscape:export-ydpi="299">
  <defs
     id="defs2">
    <marker
       inkscape:isstock="true"
       style="overflow:visible"
       id="marker5117"
       refX="0"
       refY="0"
       orient="auto"
       inkscape:stockid="Arrow1Lend">
      <path
         transform="matrix(-0.8,0,0,-0.8,-10,0)"
         style="fill:#000000;fill-opacity:1;fill-rule:evenodd;stroke:#000000;stroke-width:1.00000003pt;stroke-opacity:1"
         d="M 0,0 5,-5 -12.5,0 5,5 Z"
         id="path5115"
         inkscape:connector-curvature="0" />
    </marker>
    <marker
       inkscape:stockid="Arrow1Lstart"
       orient="auto"
       refY="0"
       refX="0"
       id="marker5049"
       style="overflow:visible"
       inkscape:isstock="true">
      <path
         id="path5047"
         d="M 0,0 5,-5 -12.5,0 5,5 Z"
         style="fill:#000000;fill-opacity:1;fill-rule:evenodd;stroke:#000000;stroke-width:1.00000003pt;stroke-opacity:1"
         transform="matrix(0.8,0,0,0.8,10,0)"
         inkscape:connector-curvature="0" />
    </marker>
    <marker
       inkscape:stockid="Arrow1Lstart"
       orient="auto"
       refY="0"
       refX="0"
       id="Arrow1Lstart"
       style="overflow:visible"
       inkscape:isstock="true">
      <path
         id="path4753"
         d="M 0,0 5,-5 -12.5,0 5,5 Z"
         style="fill:#000000;fill-opacity:1;fill-rule:evenodd;stroke:#000000;stroke-width:1.00000003pt;stroke-opacity:1"
         transform="matrix(0.8,0,0,0.8,10,0)"
         inkscape:connector-curvature="0" />
    </marker>
    <marker
       inkscape:stockid="Arrow1Lend"
       orient="auto"
       refY="0"
       refX="0"
       id="Arrow1Lend"
       style="overflow:visible"
       inkscape:isstock="true"
       inkscape:collect="always">
      <path
         id="path4756"
         d="M 0,0 5,-5 -12.5,0 5,5 Z"
         style="fill:#000000;fill-opacity:1;fill-rule:evenodd;stroke:#000000;stroke-width:1.00000003pt;stroke-opacity:1"
         transform="matrix(-0.8,0,0,-0.8,-10,0)"
         inkscape:connector-curvature="0" />
    </marker>
    <marker
       inkscape:stockid="Arrow1Lend"
       orient="auto"
       refY="0"
       refX="0"
       id="Arrow1Lend-8-1-3-3"
       style="overflow:visible"
       inkscape:isstock="true"
       inkscape:collect="always">
      <path
         id="path4756-3-0-0-6"
         d="M 0,0 5,-5 -12.5,0 5,5 Z"
         style="fill:#000000;fill-opacity:1;fill-rule:evenodd;stroke:#000000;stroke-width:1.00000003pt;stroke-opacity:1"
         transform="matrix(-0.8,0,0,-0.8,-10,0)"
         inkscape:connector-curvature="0" />
    </marker>
    <marker
       inkscape:stockid="Arrow1Lend"
       orient="auto"
       refY="0"
       refX="0"
       id="Arrow1Lend-3"
       style="overflow:visible"
       inkscape:isstock="true"
       inkscape:collect="always">
      <path
         id="path4756-6"
         d="M 0,0 5,-5 -12.5,0 5,5 Z"
         style="fill:#000000;fill-opacity:1;fill-rule:evenodd;stroke:#000000;stroke-width:1.00000003pt;stroke-opacity:1"
         transform="matrix(-0.8,0,0,-0.8,-10,0)"
         inkscape:connector-curvature="0" />
    </marker>
    <marker
       inkscape:stockid="Arrow1Lend"
       orient="auto"
       refY="0"
       refX="0"
       id="Arrow1Lend-3-2"
       style="overflow:visible"
       inkscape:isstock="true"
       inkscape:collect="always">
      <path
         id="path4756-6-6"
         d="M 0,0 5,-5 -12.5,0 5,5 Z"
         style="fill:#000000;fill-opacity:1;fill-rule:evenodd;stroke:#000000;stroke-width:1.00000003pt;stroke-opacity:1"
         transform="matrix(-0.8,0,0,-0.8,-10,0)"
         inkscape:connector-curvature="0" />
    </marker>
    <marker
       inkscape:stockid="Arrow1Lend"
       orient="auto"
       refY="0"
       refX="0"
       id="Arrow1Lend-3-2-5"
       style="overflow:visible"
       inkscape:isstock="true"
       inkscape:collect="always">
      <path
         id="path4756-6-6-9"
         d="M 0,0 5,-5 -12.5,0 5,5 Z"
         style="fill:#000000;fill-opacity:1;fill-rule:evenodd;stroke:#000000;stroke-width:1.00000003pt;stroke-opacity:1"
         transform="matrix(-0.8,0,0,-0.8,-10,0)"
         inkscape:connector-curvature="0" />
    </marker>
    <marker
       inkscape:stockid="Arrow1Lend"
       orient="auto"
       refY="0"
       refX="0"
       id="Arrow1Lend-3-2-5-2"
       style="overflow:visible"
       inkscape:isstock="true"
       inkscape:collect="always">
      <path
         id="path4756-6-6-9-8"
         d="M 0,0 5,-5 -12.5,0 5,5 Z"
         style="fill:#000000;fill-opacity:1;fill-rule:evenodd;stroke:#000000;stroke-width:1.00000003pt;stroke-opacity:1"
         transform="matrix(-0.8,0,0,-0.8,-10,0)"
         inkscape:connector-curvature="0" />
    </marker>
    <marker
       inkscape:stockid="Arrow1Lend"
       orient="auto"
       refY="0"
       refX="0"
       id="Arrow1Lend-3-2-5-9"
       style="overflow:visible"
       inkscape:isstock="true"
       inkscape:collect="always">
      <path
         id="path4756-6-6-9-4"
         d="M 0,0 5,-5 -12.5,0 5,5 Z"
         style="fill:#000000;fill-opacity:1;fill-rule:evenodd;stroke:#000000;stroke-width:1.00000003pt;stroke-opacity:1"
         transform="matrix(-0.8,0,0,-0.8,-10,0)"
         inkscape:connector-curvature="0" />
    </marker>
    <marker
       inkscape:stockid="Arrow1Lend"
       orient="auto"
       refY="0"
       refX="0"
       id="Arrow1Lend-3-2-5-2-8"
       style="overflow:visible"
       inkscape:isstock="true"
       inkscape:collect="always">
      <path
         id="path4756-6-6-9-8-4"
         d="M 0,0 5,-5 -12.5,0 5,5 Z"
         style="fill:#000000;fill-opacity:1;fill-rule:evenodd;stroke:#000000;stroke-width:1.00000003pt;stroke-opacity:1"
         transform="matrix(-0.8,0,0,-0.8,-10,0)"
         inkscape:connector-curvature="0" />
    </marker>
  </defs>
  <sodipodi:namedview
     id="base"
     pagecolor="#ffffff"
     bordercolor="#666666"
     borderopacity="1.0"
     inkscape:pageopacity="0.0"
     inkscape:pageshadow="2"
     inkscape:zoom="0.92546231"
     inkscape:cx="270.18722"
     inkscape:cy="263.44901"
     inkscape:document-units="mm"
     inkscape:current-layer="layer4"
     showgrid="true"
     inkscape:snap-intersection-paths="true"
     fit-margin-top="1"
     fit-margin-left="1"
     fit-margin-right="1"
     fit-margin-bottom="1"
     inkscape:window-width="1920"
     inkscape:window-height="1055"
     inkscape:window-x="0"
     inkscape:window-y="0"
     inkscape:window-maximized="1"
     inkscape:snap-text-baseline="true">
    <inkscape:grid
       type="xygrid"
       id="grid4747"
       originx="-17.722006"
       originy="-225.67383" />
  </sodipodi:namedview>
  <metadata
     id="metadata5">
    <rdf:RDF>
      <cc:Work
         rdf:about="">
        <dc:format>image/svg+xml</dc:format>
        <dc:type
           rdf:resource="http://purl.org/dc/dcmitype/StillImage" />
        <dc:title></dc:title>
      </cc:Work>
    </rdf:RDF>
  </metadata>
  <g
     inkscape:label="Layer 1"
     inkscape:groupmode="layer"
     id="layer1"
     transform="translate(-17.722003,32.502452)"
     style="display:inline" />
  <g
     inkscape:groupmode="layer"
     id="layer4"
     inkscape:label="Layer 4"
     style="display:inline"
     transform="translate(9.5742418,73.092536)">
    <g
       style="display:inline;opacity:1;stroke-width:1.00413811"
       id="g10311-8-7"
       transform="matrix(0.99587889,0,0,0.99587889,37.702904,-8.1226032)">
      <rect
         y="18.546434"
         x="-4.1621361"
         height="7.8937817"
         width="35.814468"
         id="rect10261-5-7"
         style="opacity:1;fill:#b2030f;fill-opacity:0.3372549;fill-rule:nonzero;stroke:none;stroke-width:0.10041382;stroke-linecap:round;stroke-linejoin:bevel;stroke-miterlimit:4;stroke-dasharray:none;stroke-dashoffset:0;stroke-opacity:0.90575915" />
      <text
         id="text10280-5-6"
         y="23.859999"
         x="14.435339"
         style="font-style:normal;font-variant:normal;font-weight:normal;font-stretch:normal;font-size:4.23333311px;line-height:100%;font-family:'Source Sans Pro';-inkscape-font-specification:'Source Sans Pro';font-variant-ligatures:normal;font-variant-caps:normal;font-variant-numeric:normal;font-feature-settings:normal;text-align:center;writing-mode:lr-tb;text-anchor:middle;opacity:1;fill:#000000;fill-opacity:1;fill-rule:nonzero;stroke:none;stroke-width:0.10041382;stroke-linecap:round;stroke-linejoin:bevel;stroke-miterlimit:4;stroke-dasharray:none;stroke-dashoffset:0;stroke-opacity:0.90575915"
         xml:space="preserve"><tspan
           style="fill:#000000;stroke:none;stroke-width:0.10041382"
           y="23.859999"
           x="14.43534"
           id="tspan10278-07-9"
           sodipodi:role="line">run_opt()</tspan></text>
    </g>
    <g
       style="display:inline;opacity:1;stroke-width:1.00413811"
       id="g10311-8-7-2"
       transform="matrix(0.99587889,0,0,0.99587889,70.775822,-70.299686)">
      <rect
         y="18.579281"
         x="-10.804091"
         height="7.9375"
         width="50.478863"
         id="rect10261-5-7-7"
         style="opacity:1;fill:#666666;fill-opacity:0.3372549;fill-rule:nonzero;stroke:none;stroke-width:0.10041381;stroke-linecap:round;stroke-linejoin:bevel;stroke-miterlimit:4;stroke-dasharray:none;stroke-dashoffset:0;stroke-opacity:0.90575915" />
      <text
         id="text10280-5-6-0"
         y="23.859999"
         x="14.435339"
         style="font-style:normal;font-variant:normal;font-weight:normal;font-stretch:normal;font-size:4.23333311px;line-height:100%;font-family:'Source Sans Pro';-inkscape-font-specification:'Source Sans Pro';font-variant-ligatures:normal;font-variant-caps:normal;font-variant-numeric:normal;font-feature-settings:normal;text-align:center;writing-mode:lr-tb;text-anchor:middle;opacity:1;fill:#000000;fill-opacity:1;fill-rule:nonzero;stroke:none;stroke-width:0.10041382;stroke-linecap:round;stroke-linejoin:bevel;stroke-miterlimit:4;stroke-dasharray:none;stroke-dashoffset:0;stroke-opacity:0.90575915"
         xml:space="preserve"><tspan
           style="fill:#000000;stroke:none;stroke-width:0.10041382"
           y="23.859999"
           x="14.435339"
           id="tspan10278-07-9-9"
           sodipodi:role="line">load_timeseries_data()</tspan></text>
    </g>
  </g>
  <g
     inkscape:groupmode="layer"
     id="layer3"
     inkscape:label="Layer 3"
     style="display:inline"
     transform="translate(9.5742418,73.092536)">
    <text
       xml:space="preserve"
       style="font-style:normal;font-variant:normal;font-weight:normal;font-stretch:normal;font-size:4.23333311px;line-height:100%;font-family:'Source Sans Pro';-inkscape-font-specification:'Source Sans Pro';font-variant-ligatures:normal;font-variant-caps:normal;font-variant-numeric:normal;font-feature-settings:normal;text-align:center;writing-mode:lr-tb;text-anchor:middle;display:inline;opacity:1;fill:#000000;fill-opacity:1;fill-rule:nonzero;stroke:none;stroke-width:0.26499999;stroke-linecap:round;stroke-linejoin:bevel;stroke-miterlimit:4;stroke-dasharray:none;stroke-dashoffset:0;stroke-opacity:0.90575915"
       x="52.078754"
       y="28.868233"
       id="text5844-9-3"
       inkscape:transform-center-x="1.8608059"
       inkscape:transform-center-y="2.0299663"><tspan
         sodipodi:role="line"
         x="52.078754"
         y="28.868233"
         style="font-style:normal;font-variant:normal;font-weight:normal;font-stretch:normal;line-height:100%;font-family:'Source Sans Pro';-inkscape-font-specification:'Source Sans Pro';fill:#000000;stroke:none;stroke-width:0.26499999"
         id="tspan9819-0-6">opt_result::OptResult</tspan></text>
    <path
       style="color:#000000;clip-rule:nonzero;display:inline;overflow:visible;visibility:visible;opacity:1;isolation:auto;mix-blend-mode:normal;color-interpolation:sRGB;color-interpolation-filters:linearRGB;solid-color:#000000;solid-opacity:1;fill:#000000;fill-opacity:1;fill-rule:evenodd;stroke:#000000;stroke-width:0.21235815;stroke-linecap:butt;stroke-linejoin:miter;stroke-miterlimit:4;stroke-dasharray:none;stroke-dashoffset:0;stroke-opacity:1;marker-end:url(#Arrow1Lend-8-1-3-3);color-rendering:auto;image-rendering:auto;shape-rendering:auto;text-rendering:auto;enable-background:accumulate"
       d="m 52.078754,18.137586 v 5.43898"
       id="path4751-7-5-7-7"
       inkscape:connector-curvature="0"
       sodipodi:nodetypes="cc" />
    <path
       style="color:#000000;clip-rule:nonzero;display:inline;overflow:visible;visibility:visible;opacity:1;isolation:auto;mix-blend-mode:normal;color-interpolation:sRGB;color-interpolation-filters:linearRGB;solid-color:#000000;solid-opacity:1;fill:#000000;fill-opacity:1;fill-rule:evenodd;stroke:#000000;stroke-width:0.21235822;stroke-linecap:butt;stroke-linejoin:miter;stroke-miterlimit:4;stroke-dasharray:none;stroke-dashoffset:0;stroke-opacity:1;color-rendering:auto;image-rendering:auto;shape-rendering:auto;text-rendering:auto;enable-background:accumulate"
       d="m 85.151675,-30.663018 v 6.566612"
       id="path4751-7-5-7-7-2-6-6"
       inkscape:connector-curvature="0"
       sodipodi:nodetypes="cc" />
    <path
       style="color:#000000;clip-rule:nonzero;display:inline;overflow:visible;visibility:visible;opacity:1;isolation:auto;mix-blend-mode:normal;color-interpolation:sRGB;color-interpolation-filters:linearRGB;solid-color:#000000;solid-opacity:1;fill:#000000;fill-opacity:1;fill-rule:evenodd;stroke:#000000;stroke-width:0.21235822;stroke-linecap:butt;stroke-linejoin:miter;stroke-miterlimit:4;stroke-dasharray:none;stroke-dashoffset:0;stroke-opacity:1;color-rendering:auto;image-rendering:auto;shape-rendering:auto;text-rendering:auto;enable-background:accumulate"
       d="M 17.682921,-30.663021 V -0.23593769"
       id="path4751-7-5-7-7-2-6-6-0"
       inkscape:connector-curvature="0"
       sodipodi:nodetypes="cc" />
  </g>
  <g
     inkscape:groupmode="layer"
     id="layer2"
     inkscape:label="Layer 2"
     style="display:inline;opacity:1"
     transform="translate(9.5742418,73.092536)">
    <g
       style="display:inline;opacity:1;stroke-width:1.00413811"
       id="g12286"
       transform="matrix(0.99587889,0,0,0.99587889,-26.982722,-48.227708)">
      <g
         transform="translate(32.630684,38.806909)"
         id="g10306"
         style="display:inline;stroke-width:1.00413811" />
    </g>
    <path
       sodipodi:nodetypes="cc"
       inkscape:connector-curvature="0"
       id="path4751"
       d="m 85.151671,-16.110934 v 9.2604095"
       style="color:#000000;clip-rule:nonzero;display:inline;overflow:visible;visibility:visible;opacity:1;isolation:auto;mix-blend-mode:normal;color-interpolation:sRGB;color-interpolation-filters:linearRGB;solid-color:#000000;solid-opacity:1;fill:#000000;fill-opacity:1;fill-rule:evenodd;stroke:#000000;stroke-width:0.2123581;stroke-linecap:butt;stroke-linejoin:miter;stroke-miterlimit:4;stroke-dasharray:none;stroke-dashoffset:0;stroke-opacity:1;marker-end:url(#Arrow1Lend);color-rendering:auto;image-rendering:auto;shape-rendering:auto;text-rendering:auto;enable-background:accumulate" />
    <g
       id="g4874"
       transform="translate(41.062171,-18.599883)">
      <rect
         transform="matrix(0.99587889,0,0,0.99587889,5.5134874,-9.5807265)"
         y="4.1492748"
         x="13.496215"
         height="7.9703465"
         width="50.478863"
         id="rect10261-0"
         style="display:inline;opacity:0.33800001;fill:#00548f;fill-opacity:1;fill-rule:nonzero;stroke:none;stroke-width:0.10041384;stroke-linecap:round;stroke-linejoin:bevel;stroke-miterlimit:4;stroke-dasharray:none;stroke-dashoffset:0;stroke-opacity:0.90575915"
         ry="0" />
      <text
         id="text10280-6"
         y="-0.15688452"
         x="44.0895"
         style="font-style:normal;font-variant:normal;font-weight:normal;font-stretch:normal;font-size:4.21588707px;line-height:100%;font-family:'Source Sans Pro';-inkscape-font-specification:'Source Sans Pro';font-variant-ligatures:normal;font-variant-caps:normal;font-variant-numeric:normal;font-feature-settings:normal;text-align:center;writing-mode:lr-tb;text-anchor:middle;display:inline;opacity:1;fill:#000000;fill-opacity:1;fill-rule:nonzero;stroke:none;stroke-width:0.10000001;stroke-linecap:round;stroke-linejoin:bevel;stroke-miterlimit:4;stroke-dasharray:none;stroke-dashoffset:0;stroke-opacity:0.90575915"
         xml:space="preserve"><tspan
           id="tspan4846"
           style="fill:#000000;stroke:none;stroke-width:0.10000001"
           y="-0.15688452"
           x="44.0895"
           sodipodi:role="line">run_clust().best_results</tspan></text>
    </g>
    <text
       xml:space="preserve"
       style="font-style:normal;font-variant:normal;font-weight:normal;font-stretch:normal;font-size:4.23333311px;line-height:100%;font-family:'Source Sans Pro';-inkscape-font-specification:'Source Sans Pro';font-variant-ligatures:normal;font-variant-caps:normal;font-variant-numeric:normal;font-feature-settings:normal;text-align:center;writing-mode:lr-tb;text-anchor:middle;display:inline;opacity:1;fill:#000000;fill-opacity:1;fill-rule:nonzero;stroke:none;stroke-width:0.26499999;stroke-linecap:round;stroke-linejoin:bevel;stroke-miterlimit:4;stroke-dasharray:none;stroke-dashoffset:0;stroke-opacity:0.90575915"
       x="85.151672"
       y="-1.5588509"
       id="text5844-8"><tspan
         sodipodi:role="line"
         x="85.151672"
         y="-1.5588509"
         style="font-style:normal;font-variant:normal;font-weight:normal;font-stretch:normal;line-height:100%;font-family:'Source Sans Pro';-inkscape-font-specification:'Source Sans Pro';fill:#000000;stroke:none;stroke-width:0.26499999"
         id="tspan11034">ts_clust_data::ClustData</tspan></text>
    <text
       xml:space="preserve"
       style="font-style:normal;font-variant:normal;font-weight:normal;font-stretch:normal;font-size:4.23333311px;line-height:100%;font-family:'Source Sans Pro';-inkscape-font-specification:'Source Sans Pro';font-variant-ligatures:normal;font-variant-caps:normal;font-variant-numeric:normal;font-feature-settings:normal;text-align:center;writing-mode:lr-tb;text-anchor:middle;display:inline;opacity:1;fill:#000000;fill-opacity:1;fill-rule:nonzero;stroke:none;stroke-width:0.26499999;stroke-linecap:round;stroke-linejoin:bevel;stroke-miterlimit:4;stroke-dasharray:none;stroke-dashoffset:0;stroke-opacity:0.90575915"
       x="83.828781"
       y="-33.308861"
       id="text5844-8-5"><tspan
         sodipodi:role="line"
         x="83.828781"
         y="-33.308861"
         style="font-style:normal;font-variant:normal;font-weight:normal;font-stretch:normal;line-height:100%;font-family:'Source Sans Pro';-inkscape-font-specification:'Source Sans Pro';fill:#000000;stroke:none;stroke-width:0.26499999"
         id="tspan11034-5">ts_input_data::ClustData</tspan></text>
    <path
       sodipodi:nodetypes="cc"
       inkscape:connector-curvature="0"
       id="path4751-0"
       d="m 85.151671,-43.892177 v 6.614576"
       style="color:#000000;clip-rule:nonzero;display:inline;overflow:visible;visibility:visible;opacity:1;isolation:auto;mix-blend-mode:normal;color-interpolation:sRGB;color-interpolation-filters:linearRGB;solid-color:#000000;solid-opacity:1;fill:#000000;fill-opacity:1;fill-rule:evenodd;stroke:#000000;stroke-width:0.2123581;stroke-linecap:butt;stroke-linejoin:miter;stroke-miterlimit:4;stroke-dasharray:none;stroke-dashoffset:0;stroke-opacity:1;marker-end:url(#Arrow1Lend-3);color-rendering:auto;image-rendering:auto;shape-rendering:auto;text-rendering:auto;enable-background:accumulate" />
    <flowRoot
       xml:space="preserve"
       id="flowRoot5885"
       style="font-style:normal;font-variant:normal;font-weight:normal;font-stretch:normal;font-size:24px;line-height:0%;font-family:'Source Sans Pro';-inkscape-font-specification:'Source Sans Pro';font-variant-ligatures:normal;font-variant-caps:normal;font-variant-numeric:normal;font-feature-settings:normal;text-align:center;writing-mode:lr-tb;text-anchor:middle;opacity:1;fill:#666666;fill-opacity:1;fill-rule:nonzero;stroke:none;stroke-width:60;stroke-linecap:round;stroke-linejoin:bevel;stroke-miterlimit:4;stroke-dasharray:none;stroke-dashoffset:0;stroke-opacity:1"
       transform="matrix(0.26458333,0,0,0.26458333,-16.420922,-7.9005199)"><flowRegion
         id="flowRegion5887"><rect
           id="rect5889"
           width="155"
           height="80"
           x="233.89641"
           y="-181.03149" /></flowRegion><flowPara
         id="flowPara5891"></flowPara></flowRoot>    <g
       style="display:inline;opacity:1;stroke-width:1.00413811"
       id="g10311-8-7-2-1"
       transform="matrix(0.99587889,0,0,0.99587889,3.307071,-70.299687)">
      <rect
         y="18.579281"
         x="-10.804091"
         height="7.9375"
         width="50.478863"
         id="rect10261-5-7-7-8"
         style="opacity:1;fill:#666666;fill-opacity:0.3372549;fill-rule:nonzero;stroke:none;stroke-width:0.10041381;stroke-linecap:round;stroke-linejoin:bevel;stroke-miterlimit:4;stroke-dasharray:none;stroke-dashoffset:0;stroke-opacity:0.90575915" />
      <text
         id="text10280-5-6-0-7"
         y="23.859999"
         x="14.435339"
         style="font-style:normal;font-variant:normal;font-weight:normal;font-stretch:normal;font-size:4.23333311px;line-height:100%;font-family:'Source Sans Pro';-inkscape-font-specification:'Source Sans Pro';font-variant-ligatures:normal;font-variant-caps:normal;font-variant-numeric:normal;font-feature-settings:normal;text-align:center;writing-mode:lr-tb;text-anchor:middle;opacity:1;fill:#000000;fill-opacity:1;fill-rule:nonzero;stroke:none;stroke-width:0.10041382;stroke-linecap:round;stroke-linejoin:bevel;stroke-miterlimit:4;stroke-dasharray:none;stroke-dashoffset:0;stroke-opacity:0.90575915"
         xml:space="preserve"><tspan
           style="fill:#000000;stroke:none;stroke-width:0.10041382"
           y="23.859999"
           x="14.435339"
           id="tspan10278-07-9-9-9"
           sodipodi:role="line">load_cep_data()</tspan></text>
    </g>
    <text
       xml:space="preserve"
       style="font-style:normal;font-variant:normal;font-weight:normal;font-stretch:normal;font-size:4.23333311px;line-height:100%;font-family:'Source Sans Pro';-inkscape-font-specification:'Source Sans Pro';font-variant-ligatures:normal;font-variant-caps:normal;font-variant-numeric:normal;font-feature-settings:normal;text-align:center;writing-mode:lr-tb;text-anchor:middle;display:inline;opacity:1;fill:#000000;fill-opacity:1;fill-rule:nonzero;stroke:none;stroke-width:0.26499999;stroke-linecap:round;stroke-linejoin:bevel;stroke-miterlimit:4;stroke-dasharray:none;stroke-dashoffset:0;stroke-opacity:0.90575915"
       x="16.360031"
       y="-33.308861"
       id="text5844-8-5-2"><tspan
         sodipodi:role="line"
         x="16.360031"
         y="-33.308861"
         style="font-style:normal;font-variant:normal;font-weight:normal;font-stretch:normal;line-height:100%;font-family:'Source Sans Pro';-inkscape-font-specification:'Source Sans Pro';fill:#000000;stroke:none;stroke-width:0.26499999"
         id="tspan11034-5-0">cep_data::OptDataCEP</tspan></text>
    <path
       sodipodi:nodetypes="cc"
       inkscape:connector-curvature="0"
       id="path4751-0-2"
       d="m 17.68292,-43.892178 v 6.614576"
       style="color:#000000;clip-rule:nonzero;display:inline;overflow:visible;visibility:visible;opacity:1;isolation:auto;mix-blend-mode:normal;color-interpolation:sRGB;color-interpolation-filters:linearRGB;solid-color:#000000;solid-opacity:1;fill:#000000;fill-opacity:1;fill-rule:evenodd;stroke:#000000;stroke-width:0.2123581;stroke-linecap:butt;stroke-linejoin:miter;stroke-miterlimit:4;stroke-dasharray:none;stroke-dashoffset:0;stroke-opacity:1;marker-end:url(#Arrow1Lend-3-2);color-rendering:auto;image-rendering:auto;shape-rendering:auto;text-rendering:auto;enable-background:accumulate" />
    <text
       xml:space="preserve"
       style="font-style:normal;font-variant:normal;font-weight:normal;font-stretch:normal;font-size:4.23333311px;line-height:100%;font-family:'Source Sans Pro';-inkscape-font-specification:'Source Sans Pro';font-variant-ligatures:normal;font-variant-caps:normal;font-variant-numeric:normal;font-feature-settings:normal;text-align:center;writing-mode:lr-tb;text-anchor:middle;display:inline;opacity:1;fill:#000000;fill-opacity:1;fill-rule:nonzero;stroke:none;stroke-width:0.26499999;stroke-linecap:round;stroke-linejoin:bevel;stroke-miterlimit:4;stroke-dasharray:none;stroke-dashoffset:0;stroke-opacity:0.90575915"
       x="52.078754"
       y="-69.027603"
       id="text5844-8-5-2-3"><tspan
         sodipodi:role="line"
         x="52.078754"
         y="-69.027603"
         style="font-style:normal;font-variant:normal;font-weight:normal;font-stretch:normal;line-height:100%;font-family:'Source Sans Pro';-inkscape-font-specification:'Source Sans Pro';fill:#000000;stroke:none;stroke-width:0.26499999"
         id="tspan11034-5-0-7">data in .csv-files</tspan></text>
    <path
       sodipodi:nodetypes="cc"
       inkscape:connector-curvature="0"
       id="path4751-0-2-2"
       d="M 36.203754,-66.381768 17.682921,-55.798434"
       style="color:#000000;clip-rule:nonzero;display:inline;overflow:visible;visibility:visible;opacity:1;isolation:auto;mix-blend-mode:normal;color-interpolation:sRGB;color-interpolation-filters:linearRGB;solid-color:#000000;solid-opacity:1;fill:#000000;fill-opacity:1;fill-rule:evenodd;stroke:#000000;stroke-width:0.2123581;stroke-linecap:butt;stroke-linejoin:miter;stroke-miterlimit:4;stroke-dasharray:none;stroke-dashoffset:0;stroke-opacity:1;marker-end:url(#Arrow1Lend-3-2-5);color-rendering:auto;image-rendering:auto;shape-rendering:auto;text-rendering:auto;enable-background:accumulate" />
    <path
       sodipodi:nodetypes="cc"
       inkscape:connector-curvature="0"
       id="path4751-0-2-2-9"
       d="m 67.953753,-66.381768 18.520834,10.583334"
       style="color:#000000;clip-rule:nonzero;display:inline;overflow:visible;visibility:visible;opacity:1;isolation:auto;mix-blend-mode:normal;color-interpolation:sRGB;color-interpolation-filters:linearRGB;solid-color:#000000;solid-opacity:1;fill:#000000;fill-opacity:1;fill-rule:evenodd;stroke:#000000;stroke-width:0.2123581;stroke-linecap:butt;stroke-linejoin:miter;stroke-miterlimit:4;stroke-dasharray:none;stroke-dashoffset:0;stroke-opacity:1;marker-end:url(#Arrow1Lend-3-2-5-2);color-rendering:auto;image-rendering:auto;shape-rendering:auto;text-rendering:auto;enable-background:accumulate" />
    <text
       xml:space="preserve"
       style="font-style:normal;font-variant:normal;font-weight:normal;font-stretch:normal;font-size:4.23333311px;line-height:100%;font-family:'Source Sans Pro';-inkscape-font-specification:'Source Sans Pro';font-variant-ligatures:normal;font-variant-caps:normal;font-variant-numeric:normal;font-feature-settings:normal;text-align:center;writing-mode:lr-tb;text-anchor:middle;display:inline;opacity:1;fill:#000000;fill-opacity:1;fill-rule:nonzero;stroke:none;stroke-width:0.26499999;stroke-linecap:round;stroke-linejoin:bevel;stroke-miterlimit:4;stroke-dasharray:none;stroke-dashoffset:0;stroke-opacity:0.90575915"
       x="93.089172"
       y="-62.413017"
       id="text5844-8-5-2-3-7"><tspan
         sodipodi:role="line"
         x="93.089172"
         y="-62.413017"
         style="font-style:italic;font-variant:normal;font-weight:normal;font-stretch:normal;font-size:3.52777767px;line-height:100%;font-family:'Source Sans Pro';-inkscape-font-specification:'Source Sans Pro Italic';fill:#000000;stroke:none;stroke-width:0.26499999"
         id="tspan11034-5-0-7-3">time series dependent</tspan><tspan
         sodipodi:role="line"
         x="93.089172"
         y="-58.179684"
         style="font-style:normal;font-variant:normal;font-weight:normal;font-stretch:normal;line-height:100%;font-family:'Source Sans Pro';-inkscape-font-specification:'Source Sans Pro';fill:#000000;stroke:none;stroke-width:0.26499999"
         id="tspan6879" /></text>
    <text
       xml:space="preserve"
       style="font-style:normal;font-variant:normal;font-weight:normal;font-stretch:normal;font-size:4.23333311px;line-height:100%;font-family:'Source Sans Pro';-inkscape-font-specification:'Source Sans Pro';font-variant-ligatures:normal;font-variant-caps:normal;font-variant-numeric:normal;font-feature-settings:normal;text-align:center;writing-mode:lr-tb;text-anchor:middle;display:inline;opacity:1;fill:#000000;fill-opacity:1;fill-rule:nonzero;stroke:none;stroke-width:0.26499999;stroke-linecap:round;stroke-linejoin:bevel;stroke-miterlimit:4;stroke-dasharray:none;stroke-dashoffset:0;stroke-opacity:0.90575915"
       x="8.4225044"
       y="-62.413017"
       id="text5844-8-5-2-3-7-6"><tspan
         sodipodi:role="line"
         x="8.4225035"
         y="-62.413017"
         style="font-style:italic;font-variant:normal;font-weight:normal;font-stretch:normal;font-size:3.52777767px;line-height:100%;font-family:'Source Sans Pro';-inkscape-font-specification:'Source Sans Pro Italic';fill:#000000;stroke:none;stroke-width:0.26499999"
         id="tspan11034-5-0-7-3-1">time series independent</tspan><tspan
         sodipodi:role="line"
         x="8.4225044"
         y="-58.179684"
         style="font-style:italic;font-variant:normal;font-weight:normal;font-stretch:normal;font-size:3.52777767px;line-height:100%;font-family:'Source Sans Pro';-inkscape-font-specification:'Source Sans Pro Italic';fill:#000000;stroke:none;stroke-width:0.26499999"
         id="tspan6902" /><tspan
         sodipodi:role="line"
         x="8.4225044"
         y="-53.94635"
         style="font-style:normal;font-variant:normal;font-weight:normal;font-stretch:normal;line-height:100%;font-family:'Source Sans Pro';-inkscape-font-specification:'Source Sans Pro';fill:#000000;stroke:none;stroke-width:0.26499999"
         id="tspan6879-2" /></text>
    <path
       sodipodi:nodetypes="cc"
       inkscape:connector-curvature="0"
       id="path4751-0-2-2-7"
       d="M 85.151671,-0.23593515 66.630837,10.347399"
       style="color:#000000;clip-rule:nonzero;display:inline;overflow:visible;visibility:visible;opacity:1;isolation:auto;mix-blend-mode:normal;color-interpolation:sRGB;color-interpolation-filters:linearRGB;solid-color:#000000;solid-opacity:1;fill:#000000;fill-opacity:1;fill-rule:evenodd;stroke:#000000;stroke-width:0.2123581;stroke-linecap:butt;stroke-linejoin:miter;stroke-miterlimit:4;stroke-dasharray:none;stroke-dashoffset:0;stroke-opacity:1;marker-end:url(#Arrow1Lend-3-2-5-9);color-rendering:auto;image-rendering:auto;shape-rendering:auto;text-rendering:auto;enable-background:accumulate" />
    <path
       sodipodi:nodetypes="cc"
       inkscape:connector-curvature="0"
       id="path4751-0-2-2-9-5"
       d="M 17.682921,-0.23593418 36.203755,10.3474"
       style="color:#000000;clip-rule:nonzero;display:inline;overflow:visible;visibility:visible;opacity:1;isolation:auto;mix-blend-mode:normal;color-interpolation:sRGB;color-interpolation-filters:linearRGB;solid-color:#000000;solid-opacity:1;fill:#000000;fill-opacity:1;fill-rule:evenodd;stroke:#000000;stroke-width:0.2123581;stroke-linecap:butt;stroke-linejoin:miter;stroke-miterlimit:4;stroke-dasharray:none;stroke-dashoffset:0;stroke-opacity:1;marker-end:url(#Arrow1Lend-3-2-5-2-8);color-rendering:auto;image-rendering:auto;shape-rendering:auto;text-rendering:auto;enable-background:accumulate" />
  </g>
</svg>
```


## Example Workflow
```julia
using ClustForOpt

# load data (electricity price day ahead market)
ts_input_data, = load_timeseries_data("DAM", "GER";K=365, T=24) #DAM

# run standard kmeans clustering algorithm to cluster into 5 representative periods, with 1000 initial starting points
clust_res = run_clust(ts_input_data;method="kmeans",representation="centroid",n_clust=5,n_init=1000)

# battery operations optimization on the clustered data
opt_res = run_opt(clust_res)
```
