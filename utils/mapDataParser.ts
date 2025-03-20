import proj4 from 'proj4';
import { SimpleObject } from '../typings/globals';

const utmProjection = '+proj=utm +zone=18 +south +ellps=WGS84 +datum=WGS84 +units=m +no_defs';
const wgs84Projection = '+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs';

type ArtifactData = SimpleObject & {
  Alimentador: SimpleObject;
  Linea: SimpleObject[];
  ElectricLinePointsByAlimentador: SimpleObject;
};

export const allElementsDataToLngLat = (rawData: Array<SimpleObject>): ArtifactData => {
  if (!rawData || rawData.length === 0) {
    return null;
  }

  // OBject to sabe all the data by "artefacts"
  const elementsByType = { ElectricLinePointsByAlimentador: {} } as ArtifactData;

  for (let i = 0; i < rawData.length; i++) {
    // DATA ALIMENTADOR =========================
    if (rawData[i].artefacto.toUpperCase() === 'ALIMENTADOR') {
      // The "Alimentador" data will be saved as an object instead an Array
      // elementsByType.Alimentador[alimentadorId] = data
      if (elementsByType.hasOwnProperty(rawData[i].artefacto)) {
        elementsByType[rawData[i].artefacto][rawData[i].id] = rawData[i];
      } else {
        elementsByType[rawData[i].artefacto] = {
          [rawData[i].id]: rawData[i]
        };
      }
      continue;
    }

    // All the elements that are not "ALIMENTADOR" should have X and Y
    if (rawData[i].y == null || !rawData[i].x == null) continue;

    const [longitude, latitude] = proj4(utmProjection, wgs84Projection, [
      Number(rawData[i].y),
      Number(rawData[i].x)
    ]);

    let artifactData: SimpleObject;

    if (rawData[i].artefacto.toUpperCase() === 'LINEA') {
      const [longitudeFinal, latitudeFinal] = proj4(utmProjection, wgs84Projection, [
        Number(rawData[i].y2),
        Number(rawData[i].x2)
      ]);

      // LINE DATA (Is saved as an array of object) ========================
      artifactData = {
        ...rawData[i],
        coordinates: [
          [longitude, latitude],
          [longitudeFinal, latitudeFinal]
        ]
      };

      const alimentadorId = rawData[i].descripcionArtefacto.alimentador_id;
      // Electric Line Coordenates grouped by alimentadorId (to hull them to create a Polygon) =======
      // Is saved as an object indexed by alimentadorId, each one of them contain an Array of object
      if (elementsByType.ElectricLinePointsByAlimentador[alimentadorId]) {
        elementsByType.ElectricLinePointsByAlimentador[alimentadorId].push(
          ...[
            [longitude, latitude],
            [longitudeFinal, latitudeFinal]
          ]
        );
      } else {
        elementsByType.ElectricLinePointsByAlimentador[alimentadorId] = [
          [longitude, latitude],
          [longitudeFinal, latitudeFinal]
        ];
      }
    } else {
      // DATA OTHER ARTEFACTS (is saved as an array of Object) ==========
      artifactData = {
        ...rawData[i],
        lng: longitude,
        lat: latitude
      };
    }

    if (elementsByType.hasOwnProperty(rawData[i].artefacto)) {
      elementsByType[rawData[i].artefacto].push(artifactData);
    } else {
      elementsByType[rawData[i].artefacto] = [artifactData];
    }
  }
  return elementsByType;
};
