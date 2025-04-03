package com.meditrackapi.Meditrack.dao.Repositories;

import com.meditrackapi.Meditrack.domain.DTOs.MedicamentoTOs.Response.ListaMedsResponse;
import com.meditrackapi.Meditrack.domain.DTOs.MedicamentoTOs.Response.MedicamentoCard;
import com.meditrackapi.Meditrack.domain.DTOs.MedicamentoTOs.Response.MedicamentoResponse;
import com.meditrackapi.Meditrack.domain.Entities.Medicamento;
import com.meditrackapi.Meditrack.domain.Entities.Usuario;
import jakarta.annotation.Nonnull;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface MedicamentoRepository extends JpaRepository<Medicamento, String> {

    @Nonnull
    Optional<Medicamento> findById(@Nonnull String id);
    Optional<Medicamento> findByCodigo(int codigo);
    @Query(
                    "SELECT med.id as medicamentoId, " +
                    "med.produto as nomeMedicamento, " +
                    "med.necessitaReceita as necessitaReceita " +
                    "FROM Medicamento med " +
                    "WHERE UPPER(produto) " +
                    "LIKE CONCAT('%', UPPER(:nome), '%')")
    List<ListaMedsResponse> findByName(@Param("nome") String nome);
    @Query(
            value = "SELECT med.id as medicamentoId, " +
                    "med.codigo as codigoMedicamento, " +
                    "med.lote as loteMedicamento, " +
                    "med.produto as nomeMedicamento, " +
                    "med.tipo as tipoMedicamento, " +
                    "med.necessita_receita as necessitaReceita, " +
                    "med.vencimento as dataVencimento, " +
                    "medposto.quantidade_estoque as quantidadeEstoque " +
                    "FROM medicamento med " +
                    "JOIN medicamento_posto medposto ON medposto.medicamento_id = med.id " +
                    "WHERE medposto.posto_id = :postoId",
            nativeQuery = true
    )
    List<MedicamentoCard> findAllByPostoId(@Param("postoId") String postoId);
}
