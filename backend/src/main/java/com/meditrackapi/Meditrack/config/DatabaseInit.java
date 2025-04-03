package com.meditrackapi.Meditrack.config;

import jakarta.annotation.PostConstruct;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.sql.SQLException;

@Component
public class DatabaseInit {

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @PostConstruct
    public void init() throws IOException, SQLException {
        Long count = jdbcTemplate.queryForObject("SELECT COUNT(*) FROM medicamento", Long.class);
        if (count != null && count == 0) {
            jdbcTemplate.execute(
                    "COPY medicamento(id, codigo, lote, produto, tipo, vencimento, necessita_receita) " +
                            "FROM '/data/medicamentos_v3.csv' DELIMITER ',' CSV HEADER;"
            );
            jdbcTemplate.execute(
                    "COPY posto(id, nome, bairro, rua, numero, linhas_onibus, telefone, latitude, longitude) " +
                            "FROM '/data/postos_v3_02.csv' DELIMITER ',' CSV HEADER;"
            );
            jdbcTemplate.execute(
                    "COPY medicamento_posto(medicamento_id, posto_id, quantidade_estoque) " +
                            "FROM '/data/medicamento_posto_v3.csv' DELIMITER ',' CSV HEADER;"
            );
            jdbcTemplate.execute(
                    "COPY usuario(id, nome_completo, cpf, email, senha, foto_perfil, data_nascimento, criado_em, tipo, posto_id, is_verificado) " +
                            "FROM '/data/funcionarios_v1.csv' DELIMITER ',' CSV HEADER;"
            );
            jdbcTemplate.execute(
                    "COPY usuario(id, nome_completo, cpf, email, senha, foto_perfil, data_nascimento, criado_em, tipo, is_verificado) " +
                            "FROM '/data/usuarios_v1.csv' DELIMITER ',' CSV HEADER;"
            );
        }
    }
}
