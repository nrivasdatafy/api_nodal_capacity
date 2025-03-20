import * as turf from '@turf/turf';
import { SimpleObject } from '../typings/globals';

import { GeoJsonProperties, Geometry, Feature } from 'geojson';
import { getColorById } from './mapColors';

export const generateFeaturesFromMapLines = (mapLines: Array<SimpleObject>) => {
  const lineCoordenatesJSON = [] as Feature<Geometry, GeoJsonProperties>[];
  if (mapLines.length > 0) {
    for (let i = 0; i < mapLines.length; i++) {
      const alimentadorId = mapLines[i].descripcionArtefacto.alimentador_id;
      const tramoId = mapLines[i].descripcionArtefacto.tramo_id;
      const featureId = `line-${alimentadorId}-${tramoId}-${i}`;
      lineCoordenatesJSON.push({
        type: 'Feature',
        properties: {
          alimentadorId,
          color: getColorById(alimentadorId || 1),
          uniqueFeatureId: featureId,
          selected: false,
          ...mapLines[i]
        },
        geometry: {
          type: 'LineString',
          coordinates: mapLines[i].coordinates
        }
      });
    }
  }
  return lineCoordenatesJSON;
};

export const generateFeaturesFromMapPoints = (mapPoints: Array<SimpleObject>) => {
  const pointCoordenatesJSON = [] as Feature<Geometry, GeoJsonProperties>[];
  if (mapPoints.length > 0) {
    for (let i = 0; i < mapPoints.length; i++) {
      if (!mapPoints[i].descripcionArtefacto) {
        console.log(`No se encontro descripcionArtefacto del mapPoints nro: ${i}`);
        console.log(mapPoints[i]);
        continue;
      }
      const alimentadorId = mapPoints[i].descripcionArtefacto.alimentador_id || 1;

      const featureId = `line-${alimentadorId}-${i}`;
      pointCoordenatesJSON.push({
        type: 'Feature',
        properties: {
          alimentadorId,
          color: getColorById(alimentadorId || 1),
          markerName: `marker-${mapPoints[i].artefacto}`,
          uniqueFeatureId: featureId,
          ...mapPoints[i]
        },
        geometry: {
          type: 'Point',
          coordinates: [mapPoints[i].lng, mapPoints[i].lat]
        }
      });
    }
  }
  return pointCoordenatesJSON;
};

// Función para agrupar puntos cercanos
function clusterPoints(points: any[], maxDistance: number) {
  const clustered = turf.clustersDbscan(turf.featureCollection(points), maxDistance, {
    units: 'meters'
  });
  return clustered;
}

export const createPolygonFeaturesByHullPoints = (electricLinesCoordinates: SimpleObject) => {
  const allHulls = [] as Array<any>;
  for (const alimentadorId in electricLinesCoordinates) {
    // crear una sola colección de puntos con todas las coordenadas
    const points = [] as Array<any>;
    electricLinesCoordinates[alimentadorId].forEach((coord: any) => {
      points.push(turf.point(coord));
    });

    // Agrupar puntos cercanos
    const maxDistance = 100; // Distancia máxima en metros para considerar puntos cercanos
    const clusteredPoints = clusterPoints(points, maxDistance);

    const hull = turf.concave(clusteredPoints, { maxEdge: 1 });
    if (!hull) {
      continue;
    }

    const parsedId = Number(alimentadorId);
    const alimentadorIdNumber = isNaN(parsedId) ? 1 : parsedId;

    hull.properties = {
      alimentadorId: alimentadorIdNumber,
      color: getColorById(alimentadorIdNumber)
    };
    allHulls.push(hull);
  }

  return allHulls;
  //const hullFeatureCollection = turf.featureCollection(allHulls);
  //return hullFeatureCollection;
};
