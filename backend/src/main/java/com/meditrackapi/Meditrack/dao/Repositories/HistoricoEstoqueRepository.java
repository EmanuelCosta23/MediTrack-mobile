package com.meditrackapi.Meditrack.dao.Repositories;

import com.meditrackapi.Meditrack.domain.DTOs.PostoTOs.Response.HistoricoEstoqueResponse;
import com.meditrackapi.Meditrack.domain.Entities.HistoricoEstoque;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface HistoricoEstoqueRepository extends JpaRepository<HistoricoEstoque, String> {
    @Query(
            value = "SELECT historico.id as registroId, " +
                    "historico.data_upload as dataUpload, " +
                    "funcionario.nome_completo as funcionarioNome " +
                    "FROM historico_estoque historico " +
                    "JOIN usuario funcionario ON funcionario.id = historico.funcionario_id " +
                    "WHERE historico.posto_id = :postoId " +
                    "ORDER BY historico.data_upload DESC",
            nativeQuery = true
    )
    List<HistoricoEstoqueResponse> findHistoricoEstoqueByPostoId(@Param("postoId") String postoId);
}
