package org.isetn;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

// Statistiques calculees en Java a partir des tables (volume faible : simple et fiable)
@RestController
@RequestMapping("/api/stats")
public class StatsController {

	@Autowired private ClasseRepository classeRepo;
	@Autowired private MatiereRepository matiereRepo;
	@Autowired private EtudiantRepository etudRepo;
	@Autowired private AbsenceRepository absenceRepo;
	@Autowired private ClassMatRepository classMatRepo;

	private static class Data {
		Map<Long, Classe> classes = new LinkedHashMap<>();
		Map<Long, Matiere> matieres = new LinkedHashMap<>();
		Map<Long, Etudiant> etudiants = new LinkedHashMap<>();
		Map<Long, Long> effectif = new HashMap<>();
		Map<Long, Long> classTotal = new HashMap<>();
		Map<Long, Set<Long>> classAbsents = new HashMap<>();
		Map<Long, Long> matTotal = new HashMap<>();
		Map<Long, Set<Long>> matAbsents = new HashMap<>();
	}

	private Data load() {
		Data d = new Data();
		for (Classe c : classeRepo.findAll()) {
			d.classes.put(c.getCodClass(), c);
			d.effectif.put(c.getCodClass(), 0L);
			d.classTotal.put(c.getCodClass(), 0L);
			d.classAbsents.put(c.getCodClass(), new HashSet<>());
		}
		for (Matiere m : matiereRepo.findAll()) {
			d.matieres.put(m.getCodMat(), m);
			d.matTotal.put(m.getCodMat(), 0L);
			d.matAbsents.put(m.getCodMat(), new HashSet<>());
		}
		for (Etudiant e : etudRepo.findAll()) {
			d.etudiants.put(e.getNce(), e);
			if (e.getClasse() != null) {
				d.effectif.merge(e.getClasse().getCodClass(), 1L, Long::sum);
			}
		}
		for (Absence a : absenceRepo.findAll()) {
			if (a.getNha() == null || a.getNha() <= 0) {
				continue;
			}
			Etudiant e = d.etudiants.get(a.getNce());
			if (e == null || e.getClasse() == null || !d.matieres.containsKey(a.getCodMat())) {
				continue;
			}
			Long cc = e.getClasse().getCodClass();
			long h = a.getNha().longValue();
			d.classTotal.merge(cc, h, Long::sum);
			d.classAbsents.computeIfAbsent(cc, k -> new HashSet<>()).add(a.getNce());
			d.matTotal.merge(a.getCodMat(), h, Long::sum);
			d.matAbsents.computeIfAbsent(a.getCodMat(), k -> new HashSet<>()).add(a.getNce());
		}
		return d;
	}

	private static long num(Map<String, Object> m, String key) {
		Object v = m.get(key);
		return v instanceof Number ? ((Number) v).longValue() : 0L;
	}

	private static Comparator<Map<String, Object>> byDesc(String valueKey, String nameKey) {
		return (x, y) -> {
			int c = Long.compare(num(y, valueKey), num(x, valueKey));
			if (c != 0) {
				return c;
			}
			return String.valueOf(x.get(nameKey)).compareToIgnoreCase(String.valueOf(y.get(nameKey)));
		};
	}

	private List<Map<String, Object>> effectifRows(Data d) {
		List<Map<String, Object>> rows = new ArrayList<>();
		for (Classe c : d.classes.values()) {
			Map<String, Object> r = new LinkedHashMap<>();
			r.put("codClass", c.getCodClass());
			r.put("nomClass", c.getNomClass());
			r.put("effectif", d.effectif.get(c.getCodClass()));
			rows.add(r);
		}
		rows.sort(byDesc("effectif", "nomClass"));
		return rows;
	}

	private List<Map<String, Object>> absClasseRows(Data d) {
		List<Map<String, Object>> rows = new ArrayList<>();
		for (Classe c : d.classes.values()) {
			Map<String, Object> r = new LinkedHashMap<>();
			r.put("codClass", c.getCodClass());
			r.put("nomClass", c.getNomClass());
			r.put("totalNha", d.classTotal.get(c.getCodClass()));
			r.put("nbAbsents", d.classAbsents.get(c.getCodClass()).size());
			r.put("effectif", d.effectif.get(c.getCodClass()));
			rows.add(r);
		}
		rows.sort(byDesc("totalNha", "nomClass"));
		return rows;
	}

	private List<Map<String, Object>> absMatiereRows(Data d) {
		List<Map<String, Object>> rows = new ArrayList<>();
		for (Matiere m : d.matieres.values()) {
			Map<String, Object> r = new LinkedHashMap<>();
			r.put("codMat", m.getCodMat());
			r.put("intMat", m.getIntMat());
			r.put("totalNha", d.matTotal.get(m.getCodMat()));
			r.put("nbAbsents", d.matAbsents.get(m.getCodMat()).size());
			rows.add(r);
		}
		rows.sort(byDesc("totalNha", "intMat"));
		return rows;
	}

	// Classes classees par nombre reel d'etudiants
	@GetMapping("/classes-effectif")
	public List<Map<String, Object>> classesEffectif() {
		return effectifRows(load());
	}

	// Classes classees par total d'heures d'absence
	@GetMapping("/absences-classes")
	public List<Map<String, Object>> absencesClasses() {
		return absClasseRows(load());
	}

	// Matieres classees par total d'heures d'absence
	@GetMapping("/absences-matieres")
	public List<Map<String, Object>> absencesMatieres() {
		return absMatiereRows(load());
	}

	// Pour une matiere donnee : dans chaque classe, combien d'etudiants absents
	@GetMapping("/matiere/{cod}/classes")
	public List<Map<String, Object>> matiereParClasse(@PathVariable Long cod) {
		Data d = load();
		if (!d.matieres.containsKey(cod)) {
			throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Matière introuvable");
		}
		Map<Long, Long> total = new HashMap<>();
		Map<Long, Set<Long>> abs = new HashMap<>();
		for (Absence a : absenceRepo.findAll()) {
			if (!cod.equals(a.getCodMat()) || a.getNha() == null || a.getNha() <= 0) {
				continue;
			}
			Etudiant e = d.etudiants.get(a.getNce());
			if (e == null || e.getClasse() == null) {
				continue;
			}
			Long cc = e.getClasse().getCodClass();
			total.merge(cc, a.getNha().longValue(), Long::sum);
			abs.computeIfAbsent(cc, k -> new HashSet<>()).add(a.getNce());
		}
		List<Map<String, Object>> rows = new ArrayList<>();
		for (ClassMat cm : classMatRepo.findByCodMat(cod)) {
			Classe c = d.classes.get(cm.getCodClass());
			if (c == null) {
				continue;
			}
			Set<Long> absents = abs.get(c.getCodClass());
			Map<String, Object> r = new LinkedHashMap<>();
			r.put("codClass", c.getCodClass());
			r.put("nomClass", c.getNomClass());
			r.put("effectif", d.effectif.get(c.getCodClass()));
			r.put("nbAbsents", absents == null ? 0 : absents.size());
			r.put("totalNha", total.getOrDefault(c.getCodClass(), 0L));
			r.put("chsm", cm.getChsm());
			rows.add(r);
		}
		rows.sort(byDesc("nbAbsents", "nomClass"));
		return rows;
	}

	// Tableau de bord : totaux + classements
	@GetMapping("/overview")
	public Map<String, Object> overview() {
		Data d = load();
		List<Map<String, Object>> eff = effectifRows(d);
		List<Map<String, Object>> absC = absClasseRows(d);
		List<Map<String, Object>> absM = absMatiereRows(d);

		long totalHeures = 0;
		for (Long v : d.classTotal.values()) {
			totalHeures += v;
		}
		Set<Long> tousAbsents = new HashSet<>();
		for (Set<Long> s : d.classAbsents.values()) {
			tousAbsents.addAll(s);
		}

		Map<String, Object> m = new LinkedHashMap<>();
		m.put("nbEtudiants", d.etudiants.size());
		m.put("nbClasses", d.classes.size());
		m.put("nbMatieres", d.matieres.size());
		m.put("totalAbsences", totalHeures);
		m.put("nbEtudiantsAbsents", tousAbsents.size());
		m.put("classePlusNombreuse", !eff.isEmpty() && num(eff.get(0), "effectif") > 0 ? eff.get(0) : null);
		m.put("classePlusAbsente", !absC.isEmpty() && num(absC.get(0), "totalNha") > 0 ? absC.get(0) : null);
		m.put("matierePlusAbsente", !absM.isEmpty() && num(absM.get(0), "totalNha") > 0 ? absM.get(0) : null);
		return m;
	}
}
