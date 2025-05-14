package com.meditrackapi.Meditrack.config;

import lombok.RequiredArgsConstructor;
import org.apache.tomcat.util.http.parser.HttpParser;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.config.Customizer;
import org.springframework.security.config.annotation.authentication.configuration.AuthenticationConfiguration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

import java.util.Arrays;
import java.util.List;

@Configuration
@EnableWebSecurity
public class SecurityConfiguration {

    private final SecurityMiddleware _securityMiddleware;

    SecurityConfiguration(SecurityMiddleware securityMiddleware){
        _securityMiddleware = securityMiddleware;
    }

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity httpSecurity) throws Exception{
        return httpSecurity
                .cors(Customizer.withDefaults())
                .csrf(AbstractHttpConfigurer::disable)
                .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .authorizeHttpRequests(authorize -> authorize
                        .requestMatchers(HttpMethod.POST, "/api/usuario").authenticated()
                        .requestMatchers(HttpMethod.POST, "/api/usuario/login").permitAll()
                        .requestMatchers(HttpMethod.POST, "/api/usuario/cadastro").permitAll()
                        .requestMatchers(HttpMethod.GET, "/api/usuario/listar").hasRole("ADMIN")
                        .requestMatchers(HttpMethod.PUT, "/api/usuario/editar").authenticated()
                        .requestMatchers(HttpMethod.PUT, "/api/usuario/trocar-senha").authenticated()
                        .requestMatchers(HttpMethod.GET, "/api/usuario/confirmar-email/{userId}/{authCode}").permitAll()
                        .requestMatchers(HttpMethod.GET, "/api/medicamento/pesquisar/{nome}").permitAll()
                        .requestMatchers(HttpMethod.GET, "/api/medicamento/{id}").permitAll()
                        .requestMatchers(HttpMethod.POST, "/api/medicamento/favoritar/{medicamentoId}").hasRole("USUARIO")
                        .requestMatchers(HttpMethod.GET, "/api/medicamento/favoritos").hasRole("USUARIO")
                        .requestMatchers(HttpMethod.POST, "/api/admin/upload-meds").hasRole("ADMIN")
                        .requestMatchers(HttpMethod.POST, "/api/admin/cadastrar-funcionario").hasRole("ADMIN")
                        .requestMatchers(HttpMethod.POST, "/api/funcionario/atualizar-estoque").hasRole("FUNCIONARIO")
                        .requestMatchers(HttpMethod.GET, "/api/funcionario/listar-meds").hasRole("FUNCIONARIO")
                        .requestMatchers(HttpMethod.GET, "/api/posto/listar-postos").permitAll()
                        .requestMatchers(HttpMethod.GET, "/api/posto/historico-estoque").hasRole("FUNCIONARIO")
                        .requestMatchers("/v3/api-docs/**", "swagger-ui/**", "swagger-ui.html", "swagger/index.html").permitAll()
                        .anyRequest().authenticated()
                )
                .addFilterBefore(_securityMiddleware, UsernamePasswordAuthenticationFilter.class)
                .build();
    }

    @Bean
    CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration configuration = new CorsConfiguration();
        
        // Para desenvolvimento: permite qualquer origem
        configuration.addAllowedOriginPattern("*");
        
        // Para produção: restringir para origens específicas
        // configuration.setAllowedOrigins(Arrays.asList(
        //     "http://localhost:5173",
        //     "http://localhost:3000",
        //     "http://localhost:8000",
        //     "http://localhost:8080",
        //     "http://localhost:9000",
        //     "http://localhost:9100",
        //     "http://localhost:59258",
        //     "http://127.0.0.1:59258"
        // ));
        
        configuration.setAllowedMethods(Arrays.asList("GET", "POST", "PUT", "DELETE", "OPTIONS"));
        configuration.setAllowedHeaders(List.of("*"));
        configuration.setAllowCredentials(true);

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", configuration);
        return source;
    }

    @Bean
    public AuthenticationManager authenticationManager(AuthenticationConfiguration authenticationConfiguration) throws Exception{
        return authenticationConfiguration.getAuthenticationManager();
    }

    @Bean
    public PasswordEncoder passwordEncoder(){
        return new BCryptPasswordEncoder();
    }
}
