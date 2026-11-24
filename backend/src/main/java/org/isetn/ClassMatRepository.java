package org.isetn;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.rest.core.annotation.RepositoryRestResource;

// cle composee : non exposee par Spring Data REST
@RepositoryRestResource(exported = false)
public interface ClassMatRepository extends JpaRepository<ClassMat, ClassMatId> {
	List<ClassMat> findByCodClass(Long codClass);

	List<ClassMat> findByCodMat(Long codMat);

	void deleteByCodClass(Long codClass);

	void deleteByCodMat(Long codMat);
}
