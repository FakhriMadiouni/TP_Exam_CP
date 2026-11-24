package org.isetn;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.rest.core.annotation.RepositoryRestResource;

// cle composee : non exposee par Spring Data REST
@RepositoryRestResource(exported = false)
public interface AbsenceRepository extends JpaRepository<Absence, AbsenceId> {
	void deleteByNce(Long nce);

	void deleteByCodMat(Long codMat);
}
