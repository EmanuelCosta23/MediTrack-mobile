package com.meditrackapi.Meditrack.service;

import com.meditrackapi.Meditrack.dao.Repositories.HistoricoEstoqueRepository;
import com.meditrackapi.Meditrack.dao.Repositories.MedicamentoRepository;
import com.meditrackapi.Meditrack.dao.Repositories.PostoRepository;
import com.meditrackapi.Meditrack.dao.Repositories.UsuarioRepository;
import com.meditrackapi.Meditrack.domain.DTOs.MedicamentoTOs.Response.MedicamentoCard;
import com.meditrackapi.Meditrack.domain.DTOs.PostoTOs.Response.HistoricoEstoqueResponse;
import com.meditrackapi.Meditrack.domain.DTOs.PostoTOs.Response.PostoComMedicamentosResponse;
import com.meditrackapi.Meditrack.domain.DTOs.PostoTOs.Response.PostoDetalhadoResponse;
import com.meditrackapi.Meditrack.domain.DTOs.PostoTOs.Response.PostoResumoResponse;
import com.meditrackapi.Meditrack.domain.Entities.Posto;
import com.meditrackapi.Meditrack.domain.Entities.Usuario;
import com.meditrackapi.Meditrack.domain.Interfaces.IPostoService;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.util.Comparator;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
public class PostoService implements IPostoService {
    private final PostoRepository _postoRepo;
    private final MedicamentoRepository _medicamentoRepo;
    private final HistoricoEstoqueRepository _historicoEstoqueRepo;
    private final UsuarioRepository _userRepo;

    public PostoService(
            PostoRepository postoRepository,
            MedicamentoRepository medicamentoRepository,
            HistoricoEstoqueRepository historicoEstoqueRepository,
            UsuarioRepository usuarioRepository) {
        _postoRepo = postoRepository;
        _medicamentoRepo = medicamentoRepository;
        _historicoEstoqueRepo = historicoEstoqueRepository;
        _userRepo = usuarioRepository;
    }

    @Override
    public List<HistoricoEstoqueResponse> getHistoricoEstoque(){
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        String loggedInUserEmail = authentication.getName();
        Usuario usuarioLogado = (Usuario) _userRepo.findByEmail(loggedInUserEmail);

        String postoId = usuarioLogado.getPosto().getId();

        return _historicoEstoqueRepo.findHistoricoEstoqueByPostoId(postoId);
    }

    @Override
    public List<PostoDetalhadoResponse> findAllPostos(){
        return _postoRepo.findAllPostos();
    }

    @Override
    public Optional<PostoComMedicamentosResponse> SearchById(String id) {
        Optional<PostoComMedicamentosResponse> postoOpt = _postoRepo.findComMedicamentosById(id);
        
        if (postoOpt.isPresent()) {
            PostoComMedicamentosResponse posto = postoOpt.get();
            List<MedicamentoCard> medicamentos = _medicamentoRepo.findAllByPostoId(posto.getId());
            posto.setMedicamentos(medicamentos);
            return Optional.of(posto);
        }
        
        return Optional.empty();
    }

    @Override
    public List<PostoResumoResponse> SearchByName(String nome) {
        return _postoRepo.findByNomeContainingIgnoreCase(nome);
    }

    @Override
    public List<PostoResumoResponse> findNearbyPostos(Double userLatitude, Double userLongitude, Double raioKm) {
        List<Posto> allPostos = _postoRepo.findAll();
        
        return allPostos.stream()
            .filter(posto -> posto.getLatitude() != null && posto.getLongitude() != null)
            .map(posto -> {
                double latitudeValue = posto.getLatitude().doubleValue();
                double longitudeValue = posto.getLongitude().doubleValue();
                
                double distancia = calcularDistancia(
                    userLatitude, userLongitude,
                    latitudeValue, longitudeValue
                );
                
                // Filtrar por raio (opcional)
                if (distancia <= raioKm) {
                    return new PostoResumoResponse(
                        posto.getId(), posto.getNome(), posto.getBairro(),
                        posto.getRua(), posto.getNumero(), posto.getLinhasOnibus(),
                        posto.getTelefone(), posto.getLatitude().toString(),
                        posto.getLongitude().toString(), distancia
                    );
                }
                return null;
            })
            .filter(posto -> posto != null)
            .sorted(Comparator.comparingDouble(PostoResumoResponse::getDistancia))
            .collect(Collectors.toList());
    }

    /**
     * Calcula a distância entre dois pontos geográficos usando a fórmula de Haversine
     * @param lat1 Latitude do ponto 1 (usuário)
     * @param lon1 Longitude do ponto 1 (usuário)
     * @param lat2 Latitude do ponto 2 (posto)
     * @param lon2 Longitude do ponto 2 (posto)
     * @return Distância em quilômetros
     */
    private double calcularDistancia(double lat1, double lon1, double lat2, double lon2) {
        final int RAIO_TERRA = 6371; // Raio da Terra em km
        
        double latDistance = Math.toRadians(lat2 - lat1);
        double lonDistance = Math.toRadians(lon2 - lon1);
        
        double a = Math.sin(latDistance / 2) * Math.sin(latDistance / 2)
                + Math.cos(Math.toRadians(lat1)) * Math.cos(Math.toRadians(lat2))
                * Math.sin(lonDistance / 2) * Math.sin(lonDistance / 2);
                
        double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        
        return RAIO_TERRA * c;
    }
}