const lineFilter = (tableName: string) => `${tableName}.x1 IS NOT NULL
    AND ${tableName}.y1 IS NOT NULL
    AND ${tableName}.x2 IS NOT NULL
    AND ${tableName}.y2 IS NOT NULL
    -- filtro chile
    AND ${tableName}.x1 BETWEEN 5000000 AND 10000000
    AND ${tableName}.y1 BETWEEN 600000 AND 1000000
    AND ${tableName}.x2 BETWEEN 5000000 AND 10000000
    AND ${tableName}.y2 BETWEEN 600000 AND 1000000`;
const commonFilter = (tableName: string) => `${tableName}.x IS NOT NULL
    AND ${tableName}.y IS NOT NULL
    -- filtro chile
    AND ${tableName}.x BETWEEN 5000000 AND 10000000
    AND ${tableName}.y BETWEEN 600000 AND 1000000`;

export const queries = {
  allArtifactsByAlimentadorId: (alimentadorId?: number) => `
SELECT
    'Transformador de distribucion' AS artefacto,
    transformador_dx.transformador_dx_id AS id,
    transformador_dx.x as x,
    transformador_dx.y as y,
    null AS x2,
    null AS y2,
    --
    jsonb_build_object(
            'artefacto', 'Transformador de distribucion',
            'empresa_id', empresa.empresa_id_origen,
            'subestacion_id', subestacion.subestacion_id_origen,
            'alimentador_id', alimentador.alimentador_id,
            'identificador_del_transformador', transformador_dx.transformador_dx_id_origen,
            'capacidad_nominal_kva', transformador_dx.cap_nom,
            'voltaje_terminal_primario_kv', transformador_dx.tension_primaria,
            'voltaje_terminal_secundario_kv', transformador_dx.tension_secundaria,
            'reactancia_porcentual', transformador_dx.z,
            'tipo_conexion', tipo_cnx.tipo_cnx,
            'nodo_alta_tension_id', nodo_alta_tension.nodo_id_origen,
            'nodo_baja_tension_id', nodo_baja_tension.nodo_id_origen,
            'demanda_minima_dia', transformador_dx.demanda_minima_dia,
            'demanda_minima_noche', transformador_dx.demanda_minima_noche,
            'demanda_maxima', transformador_dx.demanda_maxima
    ) AS descripcion_artefacto
FROM alimentador
JOIN empresa
    ON alimentador.empresa_id = empresa.empresa_id
JOIN ssee_poder
    ON empresa.empresa_id = ssee_poder.empresa_id
    AND alimentador.subestacion_id = ssee_poder.subestacion_id
JOIN subestacion
    ON alimentador.subestacion_id = subestacion.subestacion_id
JOIN transformador_dx
    ON alimentador.alimentador_id = transformador_dx.alimentador_id
JOIN tipo_cnx
    ON transformador_dx.tipo_cnx_id = tipo_cnx.tipo_cnx_id
JOIN barra_mt
    ON alimentador.barra_mt_id = barra_mt.barra_mt_id
JOIN nodo AS nodo_alta_tension
    ON transformador_dx.nodo_id_alta_tension = nodo_alta_tension.nodo_id
JOIN nodo AS nodo_baja_tension
    ON transformador_dx.nodo_id_baja_tension = nodo_baja_tension.nodo_id
WHERE
${commonFilter('transformador_dx')}
${alimentadorId ? `AND alimentador.alimentador_id = ${alimentadorId}` : ''}
UNION ALL
SELECT
    'Linea' AS artefacto,
    tramo.tramo_id,
    tramo.x1 AS x,
    tramo.y1 AS y,
    tramo.x2 AS x2,
    tramo.y2 AS y2,
    --
    jsonb_build_object(
            'artefacto', 'Linea',
            'empresa_id', empresa.empresa_id_origen,
            'alimentador_id', alimentador.alimentador_id,
            'tramo_id', tramo.tramo_id_origen,
            'tension_kv', tramo.tension,
            'largo_metros', tramo.largo,
            'numero_de_fases', tramo.numero_fases,
            'disposicion', tipo_dispositivo.tipo_dispositivo_name,
            'tipo_de_conductor', catalogo_conductor.catalogo_conductor_id_origen
    ) AS descripcion_artefacto
FROM alimentador
JOIN empresa
    ON alimentador.empresa_id = empresa.empresa_id
JOIN tramo
    ON alimentador.alimentador_id = tramo.alimentador_id
JOIN tipo_dispositivo
    ON tramo.tipo_dispositivo_id = tipo_dispositivo.tipo_dispositivo_id
JOIN catalogo_conductor
    ON tramo.catalogo_conductor_id = catalogo_conductor.catalogo_conductor_id
WHERE
${lineFilter('tramo')}
${alimentadorId ? `AND alimentador.alimentador_id = ${alimentadorId}` : ''}
UNION ALL
SELECT
    'Poste' AS artefacto,
    poste.poste_id,
    poste.x AS x,
    poste.y AS y,
    null AS x2,
    null AS y2,
    --
    jsonb_build_object(
            'artefacto', 'Poste',
            'empresa_id', empresa.empresa_id_origen,
            'alimentador_id', alimentador.alimentador_id,
            'comuna', comuna.comuna_nombre,
            'poste_id', poste.poste_id_origen,
            'tension', tipo_tension.tipo_tension_nombre,
            'altura', poste.altura_poste,
            'disposicion_postacion', poste.disposicion_postacion
    ) AS descripcion_artefacto
FROM alimentador
JOIN empresa
    ON alimentador.empresa_id = empresa.empresa_id
JOIN nodo
    ON alimentador.alimentador_id = nodo.alimentador_id
JOIN poste
    ON nodo.poste_id = poste.poste_id
JOIN comuna
    ON poste.comuna_id = comuna.comuna_id
JOIN tipo_tension
    ON poste.tipo_tension_id = tipo_tension.tipo_tension_id
WHERE
${commonFilter('poste')}
${alimentadorId ? `AND alimentador.alimentador_id = ${alimentadorId}` : ''}
UNION ALL
SELECT
    'Equipo de operacion y control' AS artefacto,
    equipo.equipo_id,
    equipo.x AS x,
    equipo.y AS y,
    null AS x2,
    null AS y2,
    --
    jsonb_build_object(
            'artefacto', 'Equipo de operacion y control',
            'empresa_id', empresa.empresa_id_origen,
            'alimentador_id', alimentador.alimentador_id,
            'equipo_id', equipo.equipo_id_origen,
            'nombre_del_equipo', equipo.equipo_nombre,
            'nodo', nodo.nodo_id_origen,
            'estado', equipo.estado,
            'tension_nominal', equipo.tension_nom,
            'tipo_de_equipo', tipo_equipo.tipo_equipo_nombre,
            'propiedad', propiedad.propiedad_descripcion,
            'ubicacion', equipo.ubicacion_prot,
            'capacidad_diseno', equipo.cap_diseno,
            'tramo', tramo.tramo_id_origen
    ) AS descripcion_artefacto
FROM alimentador
JOIN empresa
    ON alimentador.empresa_id = empresa.empresa_id
JOIN equipo
    ON alimentador.alimentador_id = equipo.alimentador_id
JOIN nodo
    ON equipo.nodo_id = nodo.nodo_id
JOIN tipo_equipo
    ON equipo.tipo_equipo_id = tipo_equipo.tipo_equipo_id
JOIN propiedad
    ON equipo.propiedad_id = propiedad.propiedad_id
JOIN tramo
    ON equipo.tramo_id = tramo.tramo_id
WHERE
${commonFilter('equipo')}
${alimentadorId ? `AND alimentador.alimentador_id = ${alimentadorId}` : ''}
UNION ALL
SELECT DISTINCT ON (alimentador.alimentador_id)
    'Alimentador' AS artefacto,
    alimentador.alimentador_id,
    null AS x,
    null AS y,
    null AS x2,
    null AS y2,
    jsonb_build_object(
            'artefacto', 'Alimentador',
            'empresa_id', empresa.empresa_id_origen,
            'subestacion_id', ssee_poder.subestacion_id,
            'alimentador_id', alimentador.alimentador_id,
            'nombre_alimentador', alimentador.alimentador_nombre,
            'transformador_poder_id', transformador_dx.transformador_dx_id_origen,
            'barra_mt_id', barra_mt.barra_mt_id_origen,
            'capacidad_diseno', alimentador.cap_diseno,
            'tension_nominal', alimentador.tension,
            'r1', alimentador.r1_coci,
            'x1', alimentador.x1_coci,
            'r0', alimentador.r0_coci,
            'x0', alimentador.x0_coci,
            'demanda_minima_kw', alimentador.dda_min_kw,
            'demanda_maxima_kw', alimentador.dda_max_kw
    ) AS descripcion_artefacto
FROM alimentador
JOIN ssee_poder
    ON ssee_poder.subestacion_id = alimentador.subestacion_id
    AND ssee_poder.empresa_id = alimentador.subestacion_empresa_id
JOIN subestacion
    ON ssee_poder.subestacion_id = subestacion.subestacion_id
JOIN empresa
    ON alimentador.empresa_id = empresa.empresa_id
JOIN transformador_dx
    ON alimentador.alimentador_id = transformador_dx.alimentador_id
LEFT JOIN barra_mt
    ON alimentador.barra_mt_id = barra_mt.barra_mt_id
${alimentadorId ? `WHERE alimentador.alimentador_id = ${alimentadorId}` : ''}
;
`,
  alimentadores: () => `SELECT DISTINCT ON (alimentador.alimentador_id)
    'Alimentador' AS artefacto,
    alimentador.alimentador_id,
    null AS x,
    null AS y,
    null AS x2,
    null AS y2,
    jsonb_build_object(
            'artefacto', 'Alimentador',
            'empresa_id', empresa.empresa_id_origen,
            'subestacion_id', ssee_poder.subestacion_id,
            'alimentador_id', alimentador.alimentador_id,
            'nombre_alimentador', alimentador.alimentador_nombre,
            'transformador_poder_id', transformador_dx.transformador_dx_id_origen,
            'barra_mt_id', barra_mt.barra_mt_id_origen,
            'capacidad_diseno', alimentador.cap_diseno,
            'tension_nominal', alimentador.tension,
            'r1', alimentador.r1_coci,
            'x1', alimentador.x1_coci,
            'r0', alimentador.r0_coci,
            'x0', alimentador.x0_coci,
            'demanda_minima_kw', alimentador.dda_min_kw,
            'demanda_maxima_kw', alimentador.dda_max_kw
    ) AS descripcion_artefacto
FROM alimentador
JOIN ssee_poder
    ON ssee_poder.subestacion_id = alimentador.subestacion_id
    AND ssee_poder.empresa_id = alimentador.subestacion_empresa_id
JOIN subestacion
    ON ssee_poder.subestacion_id = subestacion.subestacion_id
JOIN empresa
    ON alimentador.empresa_id = empresa.empresa_id
JOIN transformador_dx
    ON alimentador.alimentador_id = transformador_dx.alimentador_id
LEFT JOIN barra_mt
    ON alimentador.barra_mt_id = barra_mt.barra_mt_id
;
`
};
