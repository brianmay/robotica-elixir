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

Hooks.Map = {
    mounted() {
        let latitude = parseFloat(this.el.getAttribute("data-latitude"));
        let longitude = parseFloat(this.el.getAttribute("data-longitude"));

        let map = L.map('mapid');

        // create the tile layer with correct attribution
	      let osmUrl='https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png';
	      let osmAttrib='Map data © <a href="https://openstreetmap.org">OpenStreetMap</a> contributors';
	      let osm = new L.TileLayer(osmUrl, {minZoom: 8, maxZoom: 18, attribution: osmAttrib});
        map.addLayer(osm);
        this.map = map;

        map.setView([latitude, longitude], 16);
        this.marker = L.marker([latitude, longitude]).addTo(map);
    },

    updated() {
        let latitude = parseFloat(this.el.getAttribute("data-latitude"));
        let longitude = parseFloat(this.el.getAttribute("data-longitude"));
        let map = this.map;
        map.setView([latitude, longitude], 16);
        this.marker.setLatLng([latitude, longitude]);
    }
}

let liveSocket = new LiveSocket("/live", Socket, {hooks: Hooks});
liveSocket.connect();
