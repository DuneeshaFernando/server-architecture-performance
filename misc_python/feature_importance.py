import operator
import csv
from sklearn.ensemble import RandomForestRegressor


def load_data(filename="test.csv"):
    feature_labels = []
    features = []
    througputs = []
    avg_latencies = []

    with open(filename) as csv_file:
        csv_reader = csv.reader(csv_file, delimiter=',')
        line_count = 0
        for row in csv_reader:
            if line_count == 0:
                feature_labels.append(row[2:])
                line_count += 1
            else:
                features.append(row[2: ])
                througputs.append(float(row[1]))
                avg_latencies.append(float(row[0]))
                line_count += 1

    for i in range(len(features)):
        for j in range(len(features[0])):
            features[i][j] = float(features[i][j])

    return (feature_labels, features, avg_latencies, througputs)


feature_labels, features, avg_latencies, througputs = load_data()
feature_labels = feature_labels[0]

throughput_labels = []
avg_latency_labels = []

# Create a random forest regression
clf = RandomForestRegressor(n_estimators=1000, random_state=0, n_jobs=-1)

# Train the classifier
clf.fit(features, avg_latencies)

feature_importances = {}
for i in range(len(feature_labels)):
    feature_importances[feature_labels[i]] = clf.feature_importances_[i]

sorted_feature_importances = sorted(feature_importances.items(), key=operator.itemgetter(1))
avg_latency_labels.append(sorted_feature_importances[len(sorted_feature_importances)-1][0])

for i in range(30):
    remove_feature_lable = str(sorted_feature_importances[len(sorted_feature_importances)-1][0])
    remove_feature_index = feature_labels.index(remove_feature_lable)
    feature_labels.pop(remove_feature_index)

    # remove from feature labels

    for row in range(len(features)):
        features[row].pop(remove_feature_index)

    # Create a random forest regression
    clf = RandomForestRegressor(n_estimators=1000, random_state=0, n_jobs=-1)

    # Train the classifier
    clf.fit(features, avg_latencies)

    feature_importances = {}

    for i in range(len(feature_labels)):
        feature_importances[feature_labels[i]] = clf.feature_importances_[i]

    sorted_feature_importances = sorted(feature_importances.items(), key=operator.itemgetter(1))

    avg_latency_labels.append(sorted_feature_importances[len(sorted_feature_importances) - 1][0])


# Create a random forest regression
clf = RandomForestRegressor(n_estimators=1000, random_state=0, n_jobs=-1)

# Train the classifier
clf.fit(features, througputs)

feature_importances = {}
for i in range(len(feature_labels)):
    feature_importances[feature_labels[i]] = clf.feature_importances_[i]

sorted_feature_importances = sorted(feature_importances.items(), key=operator.itemgetter(1))
throughput_labels.append(sorted_feature_importances[len(sorted_feature_importances)-1][0])

for i in range(30):
    remove_feature_lable = str(sorted_feature_importances[len(sorted_feature_importances)-1][0])
    remove_feature_index = feature_labels.index(remove_feature_lable)
    feature_labels.pop(remove_feature_index)

    # remove from feature labels

    for row in range(len(features)):
        features[row].pop(remove_feature_index)

    # Create a random forest regression
    clf = RandomForestRegressor(n_estimators=1000, random_state=0, n_jobs=-1)

    # Train the classifier
    clf.fit(features, througputs)

    feature_importances = {}

    for i in range(len(feature_labels)):
        feature_importances[feature_labels[i]] = clf.feature_importances_[i]

    sorted_feature_importances = sorted(feature_importances.items(), key=operator.itemgetter(1))

    throughput_labels.append(sorted_feature_importances[len(sorted_feature_importances) - 1][0])

print(throughput_labels)
print()
print()
print()
print(avg_latency_labels)

intersection_features = list(set(throughput_labels) & set(avg_latency_labels))

for i in range(len(intersection_features)):
    print(str(i)+ ": " + str(intersection_features[i]))


# feature_importances = dict(sorted_feature_importances)
#
# print(feature_importances)

# sfm = SelectFromModel(clf, threshold=0.05)
#
# # Train the selector
# sfm.fit(features, througputs)
#
# for feature_list_index in sfm.get_support(indices=True):
#     print(feature_labels[0][feature_list_index])


# Apply The Full Featured Classifier To The Test Data
# throughput_pred = clf.predict(features)
#
# max_t =0
#
# for i in range(len(througputs)):
#     if(abs(througputs[i]-throughput_pred[i])>max_t):
#         max_t = abs(througputs[i]-throughput_pred[i])
# print(max_t)

# View The Accuracy Of Our Full Feature (4 Features) Model
# print(mean_absolute_error(throughput_pred, througputs))


