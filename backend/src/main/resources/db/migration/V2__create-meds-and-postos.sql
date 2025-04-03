CREATE TABLE medicamento (
    id VARCHAR(255) DEFAULT gen_random_uuid() PRIMARY KEY,
    codigo int NOT NULL,
    lote VARCHAR(255) NOT NULL,
    produto VARCHAR(255) NOT NULL,
    tipo VARCHAR(255) NOT NULL,
    vencimento DATE NOT NULL,
    necessita_receita BOOLEAN NOT NULL DEFAULT false
);

CREATE TABLE posto (
    id VARCHAR(255) DEFAULT gen_random_uuid() PRIMARY KEY,
    nome VARCHAR(255) NOT NULL,
    bairro VARCHAR(255) NOT NULL,
    rua VARCHAR(255) NOT NULL,
    numero int NOT NULL,
    linhas_onibus VARCHAR(255) NULL,
    telefone VARCHAR(255) NULL
);

CREATE TABLE medicamento_posto (
    medicamento_id VARCHAR(255) NOT NULL,
    posto_id VARCHAR(255) NOT NULL,
    quantidade_estoque int NOT NULL,
    PRIMARY KEY (medicamento_id, posto_id),
    CONSTRAINT fk_medicamento FOREIGN KEY (medicamento_id) REFERENCES medicamento(id),
    CONSTRAINT fk_posto FOREIGN KEY (posto_id) REFERENCES posto(id)
);