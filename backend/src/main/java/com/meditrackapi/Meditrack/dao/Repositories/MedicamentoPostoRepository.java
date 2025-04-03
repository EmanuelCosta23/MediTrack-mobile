package com.meditrackapi.Meditrack.dao.Repositories;

import com.meditrackapi.Meditrack.domain.Entities.auxiliar.MedicamentoPosto;
import com.meditrackapi.Meditrack.domain.Entities.auxiliar.MedicamentoPostoId;
import jakarta.transaction.Transactional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface MedicamentoPostoRepository extends JpaRepository<MedicamentoPosto, MedicamentoPostoId> {
    @Modifying
    @Transactional
    @Query("UPDATE MedicamentoPosto mp SET mp.quantidadeEstoque = :quantidade " +
            "WHERE mp.posto.id = :postoId AND mp.medicamento.id = :medicamentoId")
    int updateQuantidadeEstoque(@Param("postoId") String postoId,
                                @Param("medicamentoId") String medicamentoId,
                                @Param("quantidade") int quantidade);
}
