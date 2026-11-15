#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#define PI 3.1415926535

void gaussova_eliminacija(double **K, double *F, double *U, int N) {
    for (int i = 0; i < N - 1; i++) {
        for (int j = i + 1; j < N; j++) {
            if (fabs(K[i][i]) < 1e-12) continue; 
            double faktor = K[j][i] / K[i][i];
            for (int k = i; k < N; k++) {
                K[j][k] -= faktor * K[i][k];
            }
            F[j] -= faktor * F[i];
        }
    }
    for (int i = N - 1; i >= 0; i--) {
        U[i] = F[i];
        for (int j = i + 1; j < N; j++) {
            U[i] -= K[i][j] * U[j];
        }
        U[i] /= K[i][i];
    }
}

int main() {
    // --- 1. CITANJE ULAZNOG FAJLA
    FILE *fajl = fopen("ulaz_za_C.txt", "r");
    if (fajl == NULL) {
        printf("Greska: Fajl ulaz_za_C.txt nije pronadjen!\n");
        return 1;
    }

    int broj_komponenti;
    fscanf(fajl, "%d", &broj_komponenti);
    
    double *L_komp = malloc(broj_komponenti * sizeof(double));
    double *D_komp = malloc(broj_komponenti * sizeof(double));
    double *A_komp = malloc(broj_komponenti * sizeof(double));
    double *x_pocetak = malloc(broj_komponenti * sizeof(double));
    double *x_kraj = malloc(broj_komponenti * sizeof(double));    
    
    for (int i = 0; i < broj_komponenti; i++) fscanf(fajl, "%lf", &L_komp[i]);
    for (int i = 0; i < broj_komponenti; i++) fscanf(fajl, "%lf", &D_komp[i]);
    
    double E;
    fscanf(fajl, "%lf", &E);

    double trenutni_x = 0.0;
    for (int i = 0; i < broj_komponenti; i++) {
        A_komp[i] = (D_komp[i] * D_komp[i] * PI) / 4.0;
        x_pocetak[i] = trenutni_x;
        x_kraj[i] = trenutni_x + L_komp[i];
        trenutni_x = x_kraj[i];
    }

    double alpha, deltaT;
    fscanf(fajl, "%lf %lf", &alpha, &deltaT);

    int broj_sila;
    fscanf(fajl, "%d", &broj_sila);
    
    double *F_intenzitet = malloc(broj_sila * sizeof(double));
    double *F_x = malloc(broj_sila * sizeof(double));
    
    for (int i = 0; i < broj_sila; i++) fscanf(fajl, "%lf", &F_intenzitet[i]);
    for (int i = 0; i < broj_sila; i++) fscanf(fajl, "%lf", &F_x[i]);
    fclose(fajl);

    // --- 2. GENERISANJE ČVOROVA (MESHING) ---
    int max_cvorova = 1 + broj_komponenti + broj_sila; 
    double *temp_x = malloc(max_cvorova * sizeof(double));
    
    int k = 0;
    temp_x[k++] = 0.0; 
    for (int i = 0; i < broj_komponenti; i++) temp_x[k++] = x_kraj[i];
    for (int i = 0; i < broj_sila; i++) temp_x[k++] = F_x[i];

    for (int i = 0; i < max_cvorova - 1; i++) {
        for (int j = 0; j < max_cvorova - i - 1; j++) {
            if (temp_x[j] > temp_x[j+1]) {
                double temp = temp_x[j];
                temp_x[j] = temp_x[j+1];
                temp_x[j+1] = temp;
            }
        }
    }

    int broj_cvorova = 1; 
    for (int i = 1; i < max_cvorova; i++) {
        if (fabs(temp_x[i] - temp_x[i-1]) > 0.0001) broj_cvorova++;
    }

    double *x_cvorova = malloc(broj_cvorova * sizeof(double));
    int broj_elemenata = broj_cvorova - 1; 
    
    x_cvorova[0] = temp_x[0];
    int idx = 1;
    for (int i = 1; i < max_cvorova; i++) {
        if (fabs(temp_x[i] - temp_x[i-1]) > 0.0001) x_cvorova[idx++] = temp_x[i];
    }
    free(temp_x);

    // --- 3. MAPIRANJE SPOLJASNJIH SILA NA ČVOROVE ---
    double *F_spolja = calloc(broj_cvorova, sizeof(double));
    for (int i = 0; i < broj_sila; i++) {
        for (int j = 0; j < broj_cvorova; j++) {
            if (fabs(x_cvorova[j] - F_x[i]) < 0.001) {
                F_spolja[j] += F_intenzitet[i];
                break;
            }
        }
    }

    // --- 4. FORMIRANJE MATRICE KRUTOSTI (2D Matrica) ---
    double **K_global = malloc(broj_cvorova * sizeof(double *));
    for (int i = 0; i < broj_cvorova; i++) {
        K_global[i] = calloc(broj_cvorova, sizeof(double)); 
    }

    double *F_ukupno = calloc(broj_cvorova, sizeof(double));
    double *U = calloc(broj_cvorova, sizeof(double));

    for (int i = 0; i < broj_cvorova; i++) F_ukupno[i] = F_spolja[i];

   double *A_elementa = malloc(broj_elemenata * sizeof(double));

    for (int i = 0; i < broj_elemenata; i++) {
        double L_e = x_cvorova[i+1] - x_cvorova[i];
        
        double x_sredina = (x_cvorova[i] + x_cvorova[i+1]) / 2.0;
        double A_e = 0.0;
        for (int j = 0; j < broj_komponenti; j++) {
            if (x_sredina >= x_pocetak[j] && x_sredina <= x_kraj[j]) {
                A_e = A_komp[j];
                break;
            }
        }
        A_elementa[i] = A_e;

        double k_lokalno = (E * A_e) / L_e;
        
        K_global[i][i]         += k_lokalno;
        K_global[i+1][i+1]     += k_lokalno;
        K_global[i][i+1]       -= k_lokalno;
        K_global[i+1][i]       -= k_lokalno;

        double F_term = E * A_e * alpha * deltaT;
        F_ukupno[i]   -= F_term;
        F_ukupno[i+1] += F_term;
    }

    // --- 5. GRANIČNI USLOVI ---
    K_global[0][0] *= 1e15; 
    F_ukupno[0] = 0.0; 
    
    int zadnji = broj_cvorova - 1;
    K_global[zadnji][zadnji] *= 1e15;
    F_ukupno[zadnji] = 0.0; 

    // --- 6. REŠAVANJE SISTEMA ---
    gaussova_eliminacija(K_global, F_ukupno, U, broj_cvorova);

    // --- 7. POST-PROCESSING ZA MATLAB (PLOOTOVANJE) ---
    double *Napon = malloc(broj_elemenata * sizeof(double));
    double *N_sila = malloc(broj_elemenata * sizeof(double));
    
    for (int i = 0; i < broj_elemenata; i++) {
        double L_e = x_cvorova[i+1] - x_cvorova[i];
        double eps_mech = (U[i+1] - U[i]) / L_e - (alpha * deltaT);
        
        Napon[i] = (E * eps_mech) * 1000.0; 
        N_sila[i] = (E * eps_mech) * A_elementa[i]; 
    }

    double F_a = -N_sila[0];
    double F_b = N_sila[broj_elemenata - 1];

    FILE *izlaz = fopen("rezultati_iz_C.txt", "w");
    if (izlaz == NULL) {
        printf("Greska: Ne mogu da napravim rezultati_iz_C.txt!\n");
        return 1;
    }

    fprintf(izlaz, "%.6f %.6f\n", F_a, F_b);
    
    fprintf(izlaz, "%d\n", broj_cvorova);
    
    for (int i = 0; i < broj_cvorova; i++) fprintf(izlaz, "%.8f ", x_cvorova[i]);
    fprintf(izlaz, "\n");
    for (int i = 0; i < broj_cvorova; i++) fprintf(izlaz, "%.8f ", U[i]);
    fprintf(izlaz, "\n");

    int n_plot = broj_elemenata * 2;
    fprintf(izlaz, "%d\n", n_plot);

    for(int i = 0; i < broj_elemenata; i++) {
        fprintf(izlaz, "%.8f %.8f ", x_cvorova[i], x_cvorova[i+1]);
    }
    fprintf(izlaz, "\n");

    for(int i = 0; i < broj_elemenata; i++) {
        fprintf(izlaz, "%.8f %.8f ", U[i], U[i+1]);
    }
    fprintf(izlaz, "\n");

    for(int i = 0; i < broj_elemenata; i++) {
        fprintf(izlaz, "%.8f %.8f ", Napon[i], Napon[i]);
    }
    fprintf(izlaz, "\n");

    for(int i = 0; i < broj_elemenata; i++) {
        fprintf(izlaz, "%.8f %.8f ", N_sila[i], N_sila[i]);
    }
    fprintf(izlaz, "\n");

    fclose(izlaz);

    free(L_komp); free(D_komp); free(A_komp); 
    free(x_pocetak); free(x_kraj);
    free(F_intenzitet); free(F_x); free(x_cvorova); free(F_spolja);
    free(F_ukupno); free(U); free(A_elementa); 
    free(Napon); free(N_sila);
    
    for (int i = 0; i < broj_cvorova; i++) free(K_global[i]);
    free(K_global);

    return 0;
}