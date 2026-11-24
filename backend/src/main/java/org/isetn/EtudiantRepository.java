package org.isetn;

import java.util.List;

import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.rest.core.annotation.RepositoryRestResource;

@RepositoryRestResource
public interface EtudiantRepository extends JpaRepository<Etudiant, Long> {

	List<Etudiant> findByClasseCodClassOrderByNomAsc(Long codClass);

	long countByClasseCodClass(Long codClass);

	// Nombre reel d'etudiants par classe (comptage des lignes de la table Etudiant), du plus grand au plus petit
	@Query("select c.codClass, count(e) from Etudiant e join e.classe c "
			+ "group by c.codClass order by count(e) desc, c.codClass asc")
	List<Object[]> countParClasse(Pageable pageable);
}
