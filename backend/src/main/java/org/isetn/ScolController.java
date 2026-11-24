package org.isetn;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.format.DateTimeParseException;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.PageRequest;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

@RestController
@RequestMapping("/api")
public class ScolController {

	@Autowired private DepartementRepository departementRepo;
	@Autowired private ClasseRepository classeRepo;
	@Autowired private MatiereRepository matiereRepo;
	@Autowired private EtudiantRepository etudRepo;
	@Autowired private ClassMatRepository classMatRepo;
	@Autowired private AbsenceRepository absenceRepo;

	// ------------------------------------------------------------------ outils

	private ResponseStatusException notFound(String what) {
		return new ResponseStatusException(HttpStatus.NOT_FOUND, what + " introuvable");
	}

	private ResponseStatusException bad(String message) {
		return new ResponseStatusException(HttpStatus.BAD_REQUEST, message);
	}

	private Map<String, Object> ok() {
		Map<String, Object> m = new LinkedHashMap<>();
		m.put("ok", true);
		return m;
	}

	private static String lower(String s) {
		return s == null ? "" : s.toLowerCase();
	}

	private String text(Map<String, Object> b, String key, boolean required) {
		Object v = b.get(key);
		String s = v == null ? null : v.toString().trim();
		if (s != null && s.isEmpty()) {
			s = null;
		}
		if (required && s == null) {
			throw bad("Champ obligatoire : " + key);
		}
		return s;
	}

	private Long number(Map<String, Object> b, String key) {
		String s = text(b, key, true);
		try {
			return new BigDecimal(s.replace(',', '.')).longValue();
		} catch (NumberFormatException e) {
			throw bad("Nombre invalide : " + key);
		}
	}

	// ------------------------------------------------------------ departements

	@GetMapping("/departements")
	public List<Map<String, Object>> departements() {
		List<Map<String, Object>> out = new ArrayList<>();
		for (Departement d : departementRepo.findAll()) {
			Map<String, Object> m = new LinkedHashMap<>();
			m.put("codDept", d.getCodDept());
			m.put("nomDept", d.getNomDept());
			out.add(m);
		}
		return out;
	}

	// ----------------------------------------------------------------- classes

	private Map<String, Object> classeMap(Classe c) {
		Map<String, Object> m = new LinkedHashMap<>();
		m.put("codClass", c.getCodClass());
		m.put("nomClass", c.getNomClass());
		m.put("nbrEtud", c.getNbrEtud());
		m.put("codDept", c.getDepartement() == null ? null : c.getDepartement().getCodDept());
		m.put("departement", c.getDepartement() == null ? null : c.getDepartement().getNomDept());
		return m;
	}

	// Liste des classes (liste deroulante + ecran Classes)
	@GetMapping("/classes")
	public List<Map<String, Object>> classes() {
		List<Classe> all = new ArrayList<>(classeRepo.findAll());
		all.sort(Comparator.comparing((Classe c) -> lower(c.getNomClass())));
		List<Map<String, Object>> out = new ArrayList<>();
		for (Classe c : all) {
			Map<String, Object> m = classeMap(c);
			m.put("nbEtudiantsReel", etudRepo.countByClasseCodClass(c.getCodClass()));
			out.add(m);
		}
		return out;
	}

	private void fillClasse(Classe c, Map<String, Object> b) {
		c.setNomClass(text(b, "nomClass", true));
		Long cod = number(b, "codDept");
		c.setDepartement(departementRepo.findById(cod).orElseThrow(() -> notFound("Departement")));
	}

	@PostMapping("/classes")
	public Map<String, Object> addClasse(@RequestBody Map<String, Object> b) {
		Classe c = new Classe();
		fillClasse(c, b);
		c.setNbrEtud(0);
		return classeMap(classeRepo.save(c));
	}

	@PutMapping("/classes/{cod}")
	public Map<String, Object> updateClasse(@PathVariable Long cod, @RequestBody Map<String, Object> b) {
		Classe c = classeRepo.findById(cod).orElseThrow(() -> notFound("Classe"));
		fillClasse(c, b);
		return classeMap(classeRepo.save(c));
	}

	@DeleteMapping("/classes/{cod}")
	@Transactional
	public Map<String, Object> deleteClasse(@PathVariable Long cod) {
		if (!classeRepo.existsById(cod)) {
			throw notFound("Classe");
		}
		if (etudRepo.countByClasseCodClass(cod) > 0) {
			throw new ResponseStatusException(HttpStatus.CONFLICT,
					"Impossible de supprimer : la classe contient encore des étudiants");
		}
		classMatRepo.deleteByCodClass(cod);
		classeRepo.deleteById(cod);
		return ok();
	}

	// Matieres enseignees dans une classe (table ClassMat) avec leur CHSM
	@GetMapping("/classes/{cod}/matieres")
	public List<Map<String, Object>> matieresDeClasse(@PathVariable Long cod) {
		List<Map<String, Object>> out = new ArrayList<>();
		for (ClassMat cm : classMatRepo.findByCodClass(cod)) {
			Matiere mat = matiereRepo.findById(cm.getCodMat()).orElseThrow(() -> notFound("Matiere"));
			Map<String, Object> m = new LinkedHashMap<>();
			m.put("codMat", mat.getCodMat());
			m.put("intMat", mat.getIntMat());
			m.put("chsm", cm.getChsm());
			out.add(m);
		}
		return out;
	}

	// Question 2 : classe ayant le plus d'etudiants (comptage reel dans Etudiant, pas la colonne NbrEtud)
	@GetMapping("/classes/plus-etudiants")
	public Map<String, Object> plusEtudiants() {
		List<Object[]> rows = etudRepo.countParClasse(PageRequest.of(0, 1));
		if (rows.isEmpty()) {
			throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Aucun etudiant");
		}
		Long cod = (Long) rows.get(0)[0];
		Long total = (Long) rows.get(0)[1];
		Map<String, Object> m = classeMap(classeRepo.findById(cod).orElseThrow(() -> notFound("Classe")));
		m.put("nbEtudiantsReel", total);
		return m;
	}

	// Bouton : met a jour Classe.NbrEtud avec le comptage reel
	@PutMapping("/classes/{cod}/nbr-etud")
	@Transactional
	public Map<String, Object> majNbrEtud(@PathVariable Long cod) {
		Classe c = classeRepo.findById(cod).orElseThrow(() -> notFound("Classe"));
		c.setNbrEtud((int) etudRepo.countByClasseCodClass(cod));
		classeRepo.save(c);
		return classeMap(c);
	}

	// --------------------------------------------------------------- etudiants

	private Map<String, Object> etudiantMap(Etudiant e) {
		Map<String, Object> m = new LinkedHashMap<>();
		m.put("nce", e.getNce());
		m.put("nom", e.getNom());
		m.put("prenom", e.getPrenom());
		m.put("dateNais", e.getDateNais() == null ? null : e.getDateNais().toString());
		m.put("lieuNais", e.getLieuNais());
		m.put("codClass", e.getClasse() == null ? null : e.getClasse().getCodClass());
		m.put("nomClass", e.getClasse() == null ? null : e.getClasse().getNomClass());
		return m;
	}

	private void fillEtudiant(Etudiant e, Map<String, Object> b) {
		e.setNom(text(b, "nom", true));
		e.setPrenom(text(b, "prenom", true));
		String d = text(b, "dateNais", false);
		try {
			e.setDateNais(d == null ? null : LocalDate.parse(d));
		} catch (DateTimeParseException ex) {
			throw bad("Date invalide (format aaaa-mm-jj)");
		}
		e.setLieuNais(text(b, "lieuNais", false));
		Long cod = number(b, "codClass");
		e.setClasse(classeRepo.findById(cod).orElseThrow(() -> notFound("Classe")));
	}

	@GetMapping("/etudiants")
	public List<Map<String, Object>> etudiants() {
		List<Etudiant> all = new ArrayList<>(etudRepo.findAll());
		all.sort(Comparator.comparing((Etudiant e) -> lower(e.getNom())).thenComparing(e -> lower(e.getPrenom())));
		List<Map<String, Object>> out = new ArrayList<>();
		for (Etudiant e : all) {
			out.add(etudiantMap(e));
		}
		return out;
	}

	@PostMapping("/etudiants")
	public Map<String, Object> addEtudiant(@RequestBody Map<String, Object> b) {
		Etudiant e = new Etudiant();
		fillEtudiant(e, b);
		return etudiantMap(etudRepo.save(e));
	}

	@PutMapping("/etudiants/{nce}")
	public Map<String, Object> updateEtudiant(@PathVariable Long nce, @RequestBody Map<String, Object> b) {
		Etudiant e = etudRepo.findById(nce).orElseThrow(() -> notFound("Etudiant"));
		fillEtudiant(e, b);
		return etudiantMap(etudRepo.save(e));
	}

	@DeleteMapping("/etudiants/{nce}")
	@Transactional
	public Map<String, Object> deleteEtudiant(@PathVariable Long nce) {
		if (!etudRepo.existsById(nce)) {
			throw notFound("Etudiant");
		}
		absenceRepo.deleteByNce(nce);
		etudRepo.deleteById(nce);
		return ok();
	}

	// ---------------------------------------------------------------- matieres

	private Map<String, Object> matiereMap(Matiere m) {
		Map<String, Object> r = new LinkedHashMap<>();
		r.put("codMat", m.getCodMat());
		r.put("intMat", m.getIntMat());
		r.put("description", m.getDescription());
		return r;
	}

	@GetMapping("/matieres")
	public List<Map<String, Object>> matieres() {
		List<Matiere> all = new ArrayList<>(matiereRepo.findAll());
		all.sort(Comparator.comparing((Matiere m) -> lower(m.getIntMat())));
		List<Map<String, Object>> out = new ArrayList<>();
		for (Matiere m : all) {
			out.add(matiereMap(m));
		}
		return out;
	}

	@PostMapping("/matieres")
	public Map<String, Object> addMatiere(@RequestBody Map<String, Object> b) {
		Matiere m = new Matiere();
		m.setIntMat(text(b, "intMat", true));
		m.setDescription(text(b, "description", false));
		return matiereMap(matiereRepo.save(m));
	}

	@PutMapping("/matieres/{cod}")
	public Map<String, Object> updateMatiere(@PathVariable Long cod, @RequestBody Map<String, Object> b) {
		Matiere m = matiereRepo.findById(cod).orElseThrow(() -> notFound("Matiere"));
		m.setIntMat(text(b, "intMat", true));
		m.setDescription(text(b, "description", false));
		return matiereMap(matiereRepo.save(m));
	}

	@DeleteMapping("/matieres/{cod}")
	@Transactional
	public Map<String, Object> deleteMatiere(@PathVariable Long cod) {
		if (!matiereRepo.existsById(cod)) {
			throw notFound("Matiere");
		}
		absenceRepo.deleteByCodMat(cod);
		classMatRepo.deleteByCodMat(cod);
		matiereRepo.deleteById(cod);
		return ok();
	}

	// Classes auxquelles une matiere est affectee (table ClassMat : coef + CHSM)
	@GetMapping("/matieres/{cod}/classes")
	public List<Map<String, Object>> classesDeMatiere(@PathVariable Long cod) {
		List<Map<String, Object>> out = new ArrayList<>();
		for (ClassMat cm : classMatRepo.findByCodMat(cod)) {
			Classe c = classeRepo.findById(cm.getCodClass()).orElse(null);
			if (c == null) {
				continue;
			}
			Map<String, Object> m = new LinkedHashMap<>();
			m.put("codClass", c.getCodClass());
			m.put("nomClass", c.getNomClass());
			m.put("chsm", cm.getChsm());
			m.put("coef", cm.getCoef());
			out.add(m);
		}
		out.sort(Comparator.comparing((Map<String, Object> m) -> lower(String.valueOf(m.get("nomClass")))));
		return out;
	}

	// Affecte (ou met a jour) une matiere dans une classe : {codClass, chsm, coef}
	@PostMapping("/matieres/{cod}/classes")
	public Map<String, Object> affecter(@PathVariable Long cod, @RequestBody Map<String, Object> b) {
		if (!matiereRepo.existsById(cod)) {
			throw notFound("Matiere");
		}
		Long codClass = number(b, "codClass");
		if (!classeRepo.existsById(codClass)) {
			throw notFound("Classe");
		}
		int chsm = number(b, "chsm").intValue();
		if (chsm <= 0) {
			throw bad("CHSM doit etre superieur a 0");
		}
		String coefText = text(b, "coef", false);
		double coef = 1.0;
		if (coefText != null) {
			try {
				coef = Double.parseDouble(coefText.replace(',', '.'));
			} catch (NumberFormatException e) {
				throw bad("Coefficient invalide");
			}
		}
		classMatRepo.save(new ClassMat(cod, codClass, coef, chsm));
		return ok();
	}

	@DeleteMapping("/matieres/{cod}/classes/{codClass}")
	public Map<String, Object> retirer(@PathVariable Long cod, @PathVariable Long codClass) {
		ClassMatId id = new ClassMatId(cod, codClass);
		if (!classMatRepo.existsById(id)) {
			throw notFound("Affectation");
		}
		classMatRepo.deleteById(id);
		return ok();
	}

	// --------------------------------------------------------------- absences

	// Question 1 : etudiants d'une classe + nombre d'heures d'absence (NHA) pour une matiere et une date
	@GetMapping("/absences")
	public Map<String, Object> absences(@RequestParam Long codClass, @RequestParam Long codMat,
			@RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
		Classe c = classeRepo.findById(codClass).orElseThrow(() -> notFound("Classe"));
		Matiere mat = matiereRepo.findById(codMat).orElseThrow(() -> notFound("Matiere"));
		ClassMat cm = classMatRepo.findById(new ClassMatId(codMat, codClass))
				.orElseThrow(() -> notFound("Matiere de cette classe"));

		List<Map<String, Object>> etu = new ArrayList<>();
		for (Etudiant e : etudRepo.findByClasseCodClassOrderByNomAsc(codClass)) {
			int nha = absenceRepo.findById(new AbsenceId(codMat, e.getNce(), date))
					.map(Absence::getNha).orElse(0);
			Map<String, Object> r = new LinkedHashMap<>();
			r.put("nce", e.getNce());
			r.put("nom", e.getNom());
			r.put("prenom", e.getPrenom());
			r.put("nha", nha);
			etu.add(r);
		}
		Map<String, Object> res = new LinkedHashMap<>();
		res.put("classe", c.getNomClass());
		res.put("departement", c.getDepartement() == null ? null : c.getDepartement().getNomDept());
		res.put("matiere", mat.getIntMat());
		res.put("chsm", cm.getChsm());
		res.put("date", date.toString());
		res.put("etudiants", etu);
		return res;
	}

	// Enregistrement des absences saisies : {codMat, date, items:[{nce, nha}]}
	@PostMapping("/absences")
	@Transactional
	@SuppressWarnings("unchecked")
	public Map<String, Object> saveAbsences(@RequestBody Map<String, Object> body) {
		Long codMat = ((Number) body.get("codMat")).longValue();
		LocalDate date = LocalDate.parse((String) body.get("date"));
		for (Map<String, Object> it : (List<Map<String, Object>>) body.get("items")) {
			Long nce = ((Number) it.get("nce")).longValue();
			Integer nha = ((Number) it.get("nha")).intValue();
			absenceRepo.save(new Absence(codMat, nce, date, nha));
		}
		return ok();
	}
}
