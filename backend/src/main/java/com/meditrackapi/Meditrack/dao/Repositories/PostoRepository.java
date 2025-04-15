package com.meditrackapi.Meditrack.dao.Repositories;

import com.meditrackapi.Meditrack.domain.DTOs.PostoTOs.Response.*;
import com.meditrackapi.Meditrack.domain.Entities.Posto;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import java.util.List;
import java.util.Optional;

public interface PostoRepository extends JpaRepository<Posto, String> {

    @Query(
            value = "SELECT p.id as idPosto, " +
                    "p.nome as nomePosto, " +
                    "p.bairro as bairroPosto, " +
                    "p.rua as ruaPosto, " +
                    "p.numero as numeroPosto, " +
                    "p.linhas_onibus as linhasOnibusPosto, " +
                    "p.telefone as telefonePosto, " +
                    "CAST(p.latitude as VARCHAR) as latitudePosto, " +
                    "CAST(p.longitude as VARCHAR) as longitudePosto " +
                    "FROM posto p",
            nativeQuery = true
    )
    List<PostoDetalhadoResponse> findAllPostos();

    @Query(
            value = "SELECT p.nome AS nomePosto, " +
                    "p.bairro AS bairroPosto, " +
                    "p.rua AS ruaPosto, " +
                    "p.numero AS numeroPosto, " +
                    "p.linhas_onibus AS linhasOnibus, " +
                    "p.telefone AS telefone, " +
                    "mp.quantidade_estoque as quantidadeEstoque " +
                    "FROM posto p " +
                    "JOIN medicamento_posto mp ON p.id = mp.posto_id " +
                    "WHERE mp.medicamento_id = :id",
            nativeQuery = true
    )
    List<ListaPostosResponse> findPostosByMedicamentoId(@Param("id") String id);

    @Query(
        value = "SELECT new com.meditrackapi.Meditrack.domain.DTOs.PostoTOs.Response.PostoComMedicamentosResponse(" +
                "p.id, p.nome, " +
                "concat('', p.latitude), concat('', p.longitude)) " +
                "FROM Posto p " +
                "WHERE p.id = :id"
    )
    Optional<PostoComMedicamentosResponse> findComMedicamentosById(@Param("id") String id);

    @Query(
        value = "SELECT new com.meditrackapi.Meditrack.domain.DTOs.PostoTOs.Response.PostoResumoResponse(" +
                "p.id, p.nome, p.bairro, p.rua, p.numero, p.linhasOnibus, p.telefone, " +
                "concat('', p.latitude), concat('', p.longitude)) " +
                "FROM Posto p " +
                "WHERE UPPER(p.nome) LIKE UPPER(CONCAT('%', :nome, '%'))"
    )
    List<PostoResumoResponse> findByNomeContainingIgnoreCase(@Param("nome") String nome);
}