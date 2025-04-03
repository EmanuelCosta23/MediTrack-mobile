package com.meditrackapi.Meditrack.dao.Repositories;

import com.meditrackapi.Meditrack.domain.DTOs.MedicamentoTOs.Response.MedicamentoCard;
import com.meditrackapi.Meditrack.domain.Entities.auxiliar.UsuarioMedicamento;
import com.meditrackapi.Meditrack.domain.Entities.auxiliar.UsuarioMedicamentoId;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface UsuarioMedicamentoRepository extends JpaRepository<UsuarioMedicamento, UsuarioMedicamentoId> {
    @Query(
            value = "SELECT med.id as medicamentoId, " +
                    "med.codigo as codigoMedicamento, " +
                    "med.lote as loteMedicamento, " +
                    "med.produto as nomeMedicamento, " +
                    "med.tipo as tipoMedicamento, " +
                    "med.necessita_receita as necessitaReceita, " +
                    "med.vencimento as dataVencimento " +
                    "FROM medicamento med " +
                    "JOIN usuario_medicamento as usermed on usermed.medicamento_id = med.medicamento_id " +
                    "WHERE usermed.usuario_id = :userId"
            ,nativeQuery = true
    )
    List<MedicamentoCard> findMedicamentosByUsuarioId(@Param("userId") String userId);
}
