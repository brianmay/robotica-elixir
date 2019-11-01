// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
import css from "../css/app.css";

// webpack automatically bundles all modules in your
// entry points. Those entry points can be configured
// in "webpack.config.js".
//
// Import dependencies
//
import "phoenix_html";

// Import local files
//
// Local files can be imported directly using relative paths, for example:
// import socket from "./socket"

import {Socket} from "phoenix";
import LiveSocket from "phoenix_live_view";

let Hooks = {};

function plane(bearing) {
  // bearing = -45;
  return L.icon({
    iconUrl: `data:image/svg+xml;utf8,<svg viewBox="-5 -5 30 30" xmlns="http://www.w3.org/2000/svg">

   <g transform="rotate(${45 + parseInt(bearing)},10,10)">
   <rect x="0" y="0" width="20" height="20" stroke="black" stroke-width="0.1" fill="none" />
   <path stroke="red" stroke-width="1" fill="none" d="M 0,0 L 5,0 M 0,0 L 0,5 M 0,0 L 20,20 M 15, 5 L 5, 15 " />
   </g>

</svg>`,
      iconSize: [64, 64],
      iconAnchor: [32, 32],
  });
}

Hooks.Map = {
    mounted() {
        let latitude = parseFloat(this.el.getAttribute("data-latitude"));
        let longitude = parseFloat(this.el.getAttribute("data-longitude"));
        let heading = parseFloat(this.el.getAttribute("data-heading"));

        let map = L.map('mapid');

        // create the tile layer with correct attribution
	      let osmUrl='https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png';
	      let osmAttrib='Map data © <a href="https://openstreetmap.org">OpenStreetMap</a> contributors';
	      let osm = new L.TileLayer(osmUrl, {minZoom: 8, maxZoom: 19, attribution: osmAttrib});
        map.addLayer(osm);
        this.map = map;

        map.setView([latitude, longitude], 16);
        this.marker = L.marker([latitude, longitude], {
            icon: plane(heading),
        }).addTo(map);
    },

    updated() {
        let latitude = parseFloat(this.el.getAttribute("data-latitude"));
        let longitude = parseFloat(this.el.getAttribute("data-longitude"));
        let heading = parseFloat(this.el.getAttribute("data-heading"));
        let map = this.map;
        map.setView([latitude, longitude], 16);
        this.marker.setLatLng([latitude, longitude]).setIcon(plane(heading));
    }
}

let liveSocket = new LiveSocket("/live", Socket, {hooks: Hooks});
liveSocket.connect();
