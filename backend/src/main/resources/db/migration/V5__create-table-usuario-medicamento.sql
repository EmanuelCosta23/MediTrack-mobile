CREATE TABLE usuario_medicamento (
    usuario_id VARCHAR(255) NOT NULL,
    medicamento_id VARCHAR(255) NOT NULL,
    PRIMARY KEY (usuario_id, medicamento_id),
    CONSTRAINT fk_usuario FOREIGN KEY (usuario_id) REFERENCES usuario (id) ON DELETE CASCADE,
    CONSTRAINT fk_medicamento FOREIGN KEY (medicamento_id) REFERENCES medicamento (id) ON DELETE CASCADE
);
