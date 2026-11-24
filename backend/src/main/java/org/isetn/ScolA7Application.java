package org.isetn;

import java.time.LocalDate;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class ScolA7Application implements CommandLineRunner {
	@Autowired private DepartementRepository departementRepository;
	@Autowired private ClasseRepository classeRepository;
	@Autowired private EtudiantRepository etudiantRepository;
	@Autowired private MatiereRepository matiereRepository;
	@Autowired private ClassMatRepository classMatRepository;
	@Autowired private UserRepository userRepository;

	public static void main(String[] args) {
		SpringApplication.run(ScolA7Application.class, args);
	}

	@Override
	public void run(String... args) throws Exception {
		// Donnees de test inserees une seule fois (ddl-auto=update conserve les donnees)
		if (departementRepository.count() > 0) {
			return;
		}
		Departement ti = departementRepository.save(new Departement(null, "TI"));

		// NbrEtud volontairement a 0 : le bouton de l'ecran 2 doit le corriger
		Classe dsi33 = classeRepository.save(new Classe(null, "DSI33", 0, ti));
		Classe dsi32 = classeRepository.save(new Classe(null, "DSI32", 0, ti));
		Classe dsi31 = classeRepository.save(new Classe(null, "DSI31", 0, ti));

		LocalDate d = LocalDate.of(2004, 5, 12);
		etudiantRepository.save(new Etudiant(null, "Ben Foulen1", "Foulen1", d, "Tunis", dsi33));
		etudiantRepository.save(new Etudiant(null, "Ben Foulen2", "Foulen2", d, "Sfax", dsi33));
		etudiantRepository.save(new Etudiant(null, "Ben Foulen3", "Foulen3", d, "Sousse", dsi33));
		etudiantRepository.save(new Etudiant(null, "Ben Foulen4", "Foulen4", d, "Tunis", dsi33));
		etudiantRepository.save(new Etudiant(null, "Trabelsi", "Ali", d, "Tunis", dsi32));
		etudiantRepository.save(new Etudiant(null, "Gharbi", "Sami", d, "Bizerte", dsi32));
		etudiantRepository.save(new Etudiant(null, "Mejri", "Salma", d, "Nabeul", dsi31));

		Matiere afcp = matiereRepository.save(new Matiere(null, "AFCP", "Atelier Framework Cross Platform"));
		Matiere bd = matiereRepository.save(new Matiere(null, "BD", "Bases de donnees"));
		classMatRepository.save(new ClassMat(afcp.getCodMat(), dsi33.getCodClass(), 1.5, 45));
		classMatRepository.save(new ClassMat(afcp.getCodMat(), dsi32.getCodClass(), 1.5, 45));
		classMatRepository.save(new ClassMat(bd.getCodMat(), dsi33.getCodClass(), 2.0, 60));

		if (userRepository.count() == 0) {
			userRepository.save(new User(null, "admin@gmail.com", "admin"));
		}
	}
}
