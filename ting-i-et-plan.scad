// TING I ET PLAN DOT SCAD
// Rev. B
// Niklas Nisbeth, 2016.

// Kan sætte ting op i pæne rækker.
// Sektioner består af en eller flere vandrette rækker af... ting.
// De ting jeg har defineret er huller i forskellig størrelse.
// Så kan man lave en SVG med huller til at fræse et frontpanel,
// eller cylindre trukket lidt tilbage som man kan skære ud af en cube
// og 3D-printe.

// -1. Definer evt. dine ting som moduler, 
// Tilføj dem til section-modulet, så de matches til en tekststreng.

// 0. Definer et par konstanter.
ygrid = 20;
xgrid = 18;
threed = false;

// 1. Skriv sektionstyper, lister af lister ting :
// Sektioner er "en eller flere vandrette rækker"!
// Rækker som har færre huller end den breddeste i en kolonne
// fordeles jævnt og dumt.
section_types = [
    ["env", [["mjack", "pot", "mjack"]]],
    ["vca", [["mjack", 0, "mjack"]]],
    ["empty", [[0]]],
    ["mixer", [["mjack","mjack","mjack"],
               ["pot","pot","pot"],
               ["mjack","mjack"]]],
    ["lfo", [["pot", "mjack"],["pot", "mjack",]]]];

// 2. Skriv så en beskrivelse af layoutet, en liste af lister af sektioner.
// Hver liste i layoutet er en kolonne for sig.
layout = [["env", "env", "mixer"],["vca", "vca", "mixer"], ["lfo","lfo"]];

// 3. Giv begge to til build-modulet.
build(layout, section_types);

// 4. Bær vandet tilbage over åen.

module hole(diam) {
    if (threed) {
        translate([0,0,-4]) {
            cylinder(8, diam, diam);
        }
    } else {
        circle(diam);
    }
}

module section(vect,x,y,width) {        
    function search_for(strn, data) = search([strn], data, 
        num_returns_per_match=0)[0];
    function xsz(i) = x+(i*xgrid);
    function ysz(i) = y+(i*ygrid);
        
    for (i = [0:1:len(vect)-1]) {
        elems = len(vect[i]);
        inset = xgrid*(width-elems)/elems; // centrering
        mjacks = search_for("mjack", vect[i]);
        for (j = mjacks) {
            translate([inset+xsz(j),ysz(i),0]) {
                hole(3);
            }
        }
        
        pots = search_for("pot", vect[i]);
        for (j = pots) {
            translate([inset+xsz(j),ysz(i),0]) {
                hole(6);
            }
        }
    }
}

module build(desc, section_types) {        
    function select(vector,indices) = [for (index = indices) vector[index]];        
    function car(list) = list[0];
    function cdr(list) = select(list, [1:len(list)]);
    
    // finder første gang name er første element i en liste af par
    // overflower hvis vi leder efter noget der ikke findes
    function first_match(name, alist) = 
        (name == alist[0][0]) ? 
            alist[0] : 
            first_match(name,cdr(alist));
    
    // find startpunkt ved at lægge længden af alle de foregående sammen
    function start_sums(v,i,s=0) = (i==s ? 0 : v[i-1][1] + start_sums(v,i-1,s));
  
    // find længeste underliste
    function longest_sublist(v,i=0,s=0) = (i == (len(v))) ? s : 
        longest_sublist(v,i+1,max(s,len(v[i])));
    
    // for liste af tupler [noget, noget, bredde], find breddeste
    function widest(v,i=0,s=0) = (i == (len(v))) ? s :
        widest(v, i+1, max(s,v[i][2]));
    
    // oversæt listen af elementnavne til liste af par [type,længde]
    // hvor længde angiver højde i rækker
    function element_names_to_type_length(l) = [for (c = l) 
        let (m = first_match(c, section_types)) 
            [m[1], len(m[1]), longest_sublist(m[1])]];
        
    // oversæt listen af [type,længde] til [type,y_start]
    // ved at summere højderne af foregående sektioner og gange med grid
    function type_length_to_type_ystart(l) = [for (i = [0:len(l)-1]) 
        [l[i][0], ygrid*start_sums(l,i)]];
    
    // oversæt beskrivelsen til liste af [[type,y_start],bredde]
    columns = [for (column = desc) 
        let (l = element_names_to_type_length(column))
            [type_length_to_type_ystart(l), widest(l)]];
    
    // oversæt listen^^ til [[type,y_start],x_start,width]
    columns_xstarts = [for (i = [0:len(columns)-1])
        [columns[i][0],columns[i][1],xgrid*start_sums(columns,i)]];

    for (column = columns_xstarts) {
        for (s = column[0]) {
            section(s[0], column[2], s[1], column[1]);
        }
    }
}