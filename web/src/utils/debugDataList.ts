import { debugData } from "./debugData";

export const executeDebugData = () => {
  debugData([
    {
      action: "setVisible",
      data: true,
    },
  ]);
  
  debugData([
    {
      action: "setEnabledPages",
      data: [
        'citizen_search',
        'vehicle_search',
        'reports',
        'penal_code',
        // 'agent_management',
        // 'notice_board',
        'wanted_list',
        // 'department_management',
      ],
    }
  ])
  
  debugData([
    {
      action: "setData",
      data: {
        citizens: {
          'LA1071': {
            firstname: 'Benito',
            lastname: 'Mussolini',
            citizenId: 'LA1071',
            job: {
              job_name: 'police',
              job_label: 'LSPD',
              job_grade: 14,
              job_grade_label: 'Duce',
            },
            phoneNumber: 5554316,
            criminalRecord: {
              158: {
                crime: 'Omicidio',
                date: '2022-01-01',
                location: 'Los Santos',
                officer: 'Giuseppe Del Papa',
                victim: 'Giovanni Falcone',
              }
            },
            licenses: {
              'driver': {
                label: 'Patente di guida',
                type: 'driver',
                date: '2022-01-01',
                status: 'active',
              },
              'weapon': {
                label: 'Porto d\'armi',
                type: 'weapon',
                date: '2022-01-01',
                status: 'active',
              },
              'weapon2': {
                label: 'Porto d\'armi livello 2',
                type: 'weapon2',
                date: '2022-01-01',
                status: 'active',
              },
            },
            properties: {
              'LS001': {
                label: 'Casa',
                address: 'Viale dei Pini 12',
                city: 'Los Santos',
              },
            },
            wanted: false,
            town: 'Los Santos',
            image: 'https://img.ilgcdn.com/sites/default/files/styles/xl/public/foto/2015/06/13/1434208945-benito-mussolini.jpg?_=1449907708'
          },
          'LA1072': {
            firstname: 'Adolf',
            lastname: 'Hitler',
            citizenId: 'LA1072',
            image: 'https://cdn.britannica.com/58/129958-050-C0EF01A4/Adolf-Hitler-1933.jpg',
          },
          'LA1073': {
            firstname: 'Joseph',
            lastname: 'Stalin',
            citizenId: 'LA1073',
            // image: 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcS-GRhIZw2HUMX7wPjLkkMnEeM-WBAqqujMAA&s',
          },
          'LA1074': {
            firstname: 'Gianluca',
            lastname: 'Causio',
            citizenId: 'LA1074',
            wanted: true,
            image: 'https://i.postimg.cc/J0yht6cP/image.png',
          },
          'LA1075': {
            firstname: 'Matteo Messina',
            lastname: 'Denaro',
            citizenId: 'LA1075',
            image: 'https://i.guim.co.uk/img/media/e662adab3da74237024aeed48c65640195be61a1/308_737_2648_1589/master/2648.jpg?width=465&dpr=1&s=none',
          },
          'LA1076': {
            firstname: 'Salvatore',
            lastname: 'Riina',
            citizenId: 'LA1076',
            image: 'https://www.avvenire.it/c/2017/PublishingImages/3166ef94b6364bf18f15875dc847206e/riina.jpg?width=1024',
          },
          'LA1077': {
            firstname: 'Bernardo',
            lastname: 'Provenzano',
            citizenId: 'LA1077',
            // image: 'https://encrypted-tbn2.gstatic.com/images?q=tbn:ANd9GcQUmTCu9BCce0N2Qa4x5Fvjxbz_V5Z55ZjPzO0eInfjPjQlTEio',
          },
          'LA1078': {
            firstname: 'Massimo',
            lastname: 'Bossetti',
            citizenId: 'LA1078',
            job: {
              job_name: 'worker',
              job_label: 'Muratore',
              job_grade: 1,
              job_grade_label: 'Muratore',
            },
            criminalRecord: {
              159: {
                crime: 'Innocenza',
                date: '2010-01-01',
                location: 'Los Santos',
                officer: 'Letizia Ruggeri',
                victim: 'Yara Gambirasio',
              },
              160: {
                crime: 'Innocenza',
                date: '2014-01-01',
                location: 'Los Santos',
                officer: 'Letizia Ruggeri',
                victim: 'Yara Gambirasio',
              },
              161: {
                crime: 'Innocenza',
                date: '2018-01-01',
                location: 'Los Santos',
                officer: 'Letizia Ruggeri',
                victim: 'Yara Gambirasio',
              },
              162: {
                crime: 'Innocenza',
                date: '2022-01-01',
                location: 'Los Santos',
                officer: 'Letizia Ruggeri',
                victim: 'Yara Gambirasio',
              },
              163: {
                crime: 'Innocenza',
                date: '2026-01-01',
                location: 'Los Santos',
                officer: 'Letizia Ruggeri',
                victim: 'Yara Gambirasio',
              },
              164: {
                crime: 'Innocenza',
                date: '2030-01-01',
                location: 'Los Santos',
                officer: 'Letizia Ruggeri',
                victim: 'Yara Gambirasio',
              },
              165: {
                crime: 'Innocenza',
                date: '2034-01-01',
                location: 'Los Santos',
                officer: 'Letizia Ruggeri',
                victim: 'Yara Gambirasio',
              },
              166: {
                crime: 'Innocenza',
                date: '2038-01-01',
                location: 'Los Santos',
                officer: 'Letizia Ruggeri',
                victim: 'Yara Gambirasio',
              },
            },
            image: 'https://bergamo.corriere.it/methode_image/2022/12/07/Bergamo/Foto%20Bergamo%20-%20Trattate/304.0.757609628-kTUF-U33905927394517z-656x492@Corriere-Web-Bergamo.jpg',
          },
        },
        vehicles: {
          'MD9184LS': {
            model: 'Iveco Daily',
            plate: 'MD9184LS',
            buyDate: '2022-01-01',
            owner: 'LA1078',
          },
          'S49B34DG': {
            model: 'akuma',
            plate: 'S49B34DG',
            buyDate: '2019-01-01',
            owner: 'S49414',
          },
          'AB1234CD': {
            model: 'zentorno',
            plate: 'AB1234CD',
            buyDate: '2021-03-15',
            owner: 'LA1072',
          },
          'EF5678GH': {
            model: 'adder',
            plate: 'EF5678GH',
            buyDate: '2020-07-22',
            owner: 'LA1073',
          },
          'IJ9101KL': {
            model: 'entityxf',
            plate: 'IJ9101KL',
            buyDate: '2018-11-30',
            owner: 'LA1074',
          },
          'MN2345OP': {
            model: 'cheetah',
            plate: 'MN2345OP',
            buyDate: '2017-05-10',
            owner: 'LA1075',
          },
          'QR6789ST': {
            model: 'turismor',
            plate: 'QR6789ST',
            buyDate: '2016-09-18',
            owner: 'LA1076',
          },
          'UV0123WX': {
            model: 'infernus',
            plate: 'UV0123WX',
            buyDate: '2015-02-25',
            owner: 'LA1077',
          },
          'YZ4567AB': {
            model: 'vacca',
            plate: 'YZ4567AB',
            buyDate: '2014-06-05',
            owner: 'LA1078',
          },
          'CD8901EF': {
            model: 'bullet',
            plate: 'CD8901EF',
            buyDate: '2013-12-12',
            owner: 'LA1071',
          },
          'GH2345IJ': {
            model: 'voltic',
            plate: 'GH2345IJ',
            buyDate: '2012-08-20',
            owner: 'LA1072',
          },
          'KL6789MN': {
            model: 'banshee',
            plate: 'KL6789MN',
            buyDate: '2011-04-14',
            owner: 'LA1073',
          },
        },
        penalCode: {
          1: {
            crime: 'Omicidio',
            fine: 10000,
            jailTime: 500,
          },
          2: {
            crime: 'Rapina',
            fine: 5000,
            jailTime: 300,
          },
          3: {
            crime: 'Furto',
            fine: 3000,
            jailTime: 200,
          },
          4: {
            crime: 'Estorsione',
            fine: 2000,
            jailTime: 100,
          },
          5: {
            crime: 'Rissa',
            fine: 1000,
            jailTime: 50,
          },
          6: {
            crime: 'Vandalismo',
            fine: 500,
            jailTime: 25,
          },
          7: {
            crime: 'Guida in stato di ebbrezza',
            fine: 2000,
            jailTime: 100,
          },
          8: {
            crime: 'Blastare gente in live',
            fine: 10000,
            jailTime: 500,
          }
        },
        reports: {
          1: {
            id: 1,
            title: 'Sospetto omicidio',
            description: 'Sospettato di omicidio di Giovanni Falcone, ricercato in tutta la città. Aveva con sé un\'arma da fuoco e un\'auto di colore nero. Lui era negro',
            officer: 'Giuseppe Del Papa',
            date: '2022-01-01',
            location: 'Los Santos, La Mesa Police Department',
            tags: [
              1,
              2,
            ]
          },
          2: {
            id: 2,
            title: 'Testtt',
            description: 'is joining a negro',
            date: '2020-07-01',
            location: 'Russia'
          },
          3: {
            id: 3,
            title: 'Rapina in banca',
            description: 'Rapina alla banca centrale di Los Santos. I sospettati sono fuggiti con un bottino di 1 milione di dollari.',
            officer: 'Mario Rossi',
            date: '2022-02-15',
            location: 'Los Santos, Banca Centrale',
            tags: [2, 3, 5]
          },
          4: {
            id: 4,
            title: 'Furto d\'auto',
            description: 'Furto di un\'auto sportiva nel quartiere di Vinewood. Il sospettato è stato visto fuggire verso nord.',
            officer: 'Luigi Bianchi',
            date: '2022-03-10',
            location: 'Los Santos, Vinewood',
            tags: [3]
          },
          5: {
            id: 5,
            title: 'Estorsione',
            description: 'Estorsione ai danni di un commerciante locale. Il sospettato ha richiesto una somma di 5000 dollari.',
            officer: 'Antonio Verdi',
            date: '2022-04-05',
            location: 'Los Santos, Centro',
            tags: [4]
          },
          6: {
            id: 6,
            title: 'Rissa in strada',
            description: 'Rissa tra due gruppi di persone nel quartiere di Davis. Diversi feriti sono stati trasportati in ospedale.',
            officer: 'Francesco Neri',
            date: '2022-05-20',
            location: 'Los Santos, Davis',
            tags: [5]
          },
          7: {
            id: 7,
            title: 'Vandalismo',
            description: 'Atto di vandalismo contro una scuola pubblica. I sospettati hanno danneggiato diverse aule e attrezzature.',
            officer: 'Giovanni Rossi',
            date: '2022-06-15',
            location: 'Los Santos, Scuola Pubblica',
            tags: [6]
          },
          8: {
            id: 8,
            title: 'Guida in stato di ebbrezza',
            description: 'Un individuo è stato fermato per guida in stato di ebbrezza. Il tasso alcolemico era oltre il limite consentito.',
            officer: 'Paolo Bianchi',
            date: '2022-07-10',
            location: 'Los Santos, Autostrada',
            tags: [7]
          },
          9: {
            id: 9,
            title: 'Omicidio',
            description: 'Omicidio di un cittadino nel quartiere di Mirror Park. Il sospettato è ancora a piede libero.',
            officer: 'Marco Verdi',
            date: '2022-08-05',
            location: 'Los Santos, Mirror Park',
            tags: [1]
          },
          10: {
            id: 10,
            title: 'Rapina a mano armata',
            description: 'Rapina a mano armata in un negozio di alimentari. Il sospettato ha minacciato il cassiere con una pistola.',
            officer: 'Luca Neri',
            date: '2022-09-01',
            location: 'Los Santos, Negozio di alimentari',
            tags: [2]
          },
          11: {
            id: 11,
            title: 'Furto con scasso',
            description: 'Furto con scasso in una gioielleria. I sospettati hanno rubato gioielli per un valore di 50000 dollari.',
            officer: 'Andrea Rossi',
            date: '2022-10-20',
            location: 'Los Santos, Gioielleria',
            tags: [3]
          },
          12: {
            id: 12,
            title: 'Aggressione',
            description: 'Aggressione ai danni di un passante. #Il sospettato ha colpito la vittima con un oggetto contundente.',
            officer: 'Stefano Bianchi',
            date: '2022-11-15',
            location: 'Los Santos, Parco',
            tags: [5],
            involved: [
              'LA1071',
              'LA1072',
            ]
          }
        },
        wantedList: {
          1: {
            id: 1,
            citizen: 'LA1074',
            reason: 'Dittatura in stato democratico',
            wantedBy: 'LSPD',
          }
        },
        tags: {
          1: {
            id: 1,
            label: '⚠️ Importante',
            color: '#900000',
          },
          2: {
            id: 2,
            label: '🔫 Armi',
            color: '#000090',
          },
          3: {
            id: 3,
            label: '💰 Rapina',
            color: '#009000',
          },
          4: {
            id: 4,
            label: '💸 Estorsione',
            color: '#009090',
          },
          5: {
            id: 5,
            label: '👊 Rissa',
            color: '#900090',
          },
          6: {
            id: 6,
            label: '🎨 Vandalismo',
            color: '#909000',
          },
          7: {
            id: 7,
            label: '🍺 Alcol',
            color: '#909090',
          },
        }
      },
    }
  ])
  
  debugData([
    {
      action: "setConfig",
      data: {
        window: {
          height: 720,
          width: 1080,
        },
        borderImage: {
          widthOffset: 100,
          heightOffset: 140,
        },
        Debug: true,
      }
    },
  ]);
  
  debugData([
    {
      action: "setPlayerData",
      data: {
        firstName: 'Giuseppe',
        lastName: 'Del Papa',
        grade: 'Officer',
      }
    }
  ]);
  
  debugData([
    {
      action: "setTheme",
      data: "police",
    },
  ]);

};
